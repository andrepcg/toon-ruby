# TOON for Ruby

**Token-Oriented Object Notation** is a compact, human-readable format designed for passing structured data to Large Language Models with significantly reduced token usage.

This is a Ruby port of the [TOON library](https://github.com/johannschopplich/toon) originally written in TypeScript.

## Why TOON?

AI is becoming cheaper and more accessible, but larger context windows allow for larger data inputs as well. **LLM tokens still cost money** – and standard JSON is verbose and token-expensive:

```json
{
  "users": [
    { "id": 1, "name": "Alice", "role": "admin" },
    { "id": 2, "name": "Bob", "role": "user" }
  ]
}
```

TOON conveys the same information with **fewer tokens**:

```
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toon-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install toon-ruby
```

## Quick Start

```ruby
require 'toon'

data = {
  'user' => {
    'id' => 123,
    'name' => 'Ada',
    'tags' => ['reading', 'gaming'],
    'active' => true,
    'preferences' => []
  }
}

puts Toon.encode(data)
```

Output:

```
user:
  id: 123
  name: Ada
  tags[2]: reading,gaming
  active: true
  preferences[0]:
```

## Key Features

- 💸 **Token-efficient:** typically 30–60% fewer tokens than JSON
- 🤿 **LLM-friendly guardrails:** explicit lengths and field lists help models validate output
- 🍱 **Minimal syntax:** removes redundant punctuation (braces, brackets, most quotes)
- 📐 **Indentation-based structure:** replaces braces with whitespace for better readability
- 🧺 **Tabular arrays:** declare keys once, then stream rows without repetition

## API

### `Toon.encode(value, **options)`

Converts any value to TOON format.

**Parameters:**

- `value` – Any value to encode (Hash, Array, primitives, or nested structures)
- `indent` – Number of spaces per indentation level (default: `2`)
- `delimiter` – Delimiter for array values and tabular rows: `','`, `"\t"`, or `'|'` (default: `','`)
- `length_marker` – Optional marker to prefix array lengths: `'#'` or `false` (default: `false`)

**Returns:**

A TOON-formatted string with no trailing newline or spaces.

**Examples:**

```ruby
# Basic usage
Toon.encode({ 'id' => 1, 'name' => 'Ada' })
# => "id: 1\nname: Ada"

# Tabular arrays
items = [
  { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
  { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
]
Toon.encode({ 'items' => items })
# => "items[2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5"

# Custom delimiter (tab)
Toon.encode(items, delimiter: "\t")
# => "items[2\t]{sku\tqty\tprice}:\n  A1\t2\t9.99\n  B2\t1\t14.5"

# Length marker
Toon.encode({ 'tags' => ['a', 'b', 'c'] }, length_marker: '#')
# => "tags[#3]: a,b,c"
```

## Format Overview

### Objects

Simple objects with primitive values:

```ruby
Toon.encode({
  'id' => 123,
  'name' => 'Ada',
  'active' => true
})
```

```
id: 123
name: Ada
active: true
```

Nested objects:

```ruby
Toon.encode({
  'user' => {
    'id' => 123,
    'name' => 'Ada'
  }
})
```

```
user:
  id: 123
  name: Ada
```

### Arrays

#### Primitive Arrays (Inline)

```ruby
Toon.encode({ 'tags' => ['admin', 'ops', 'dev'] })
```

```
tags[3]: admin,ops,dev
```

#### Arrays of Objects (Tabular)

When all objects share the same primitive fields, TOON uses an efficient **tabular format**:

```ruby
Toon.encode({
  'items' => [
    { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
    { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
  ]
})
```

```
items[2]{sku,qty,price}:
  A1,2,9.99
  B2,1,14.5
```

#### Mixed and Non-Uniform Arrays

Arrays that don't meet the tabular requirements use list format:

```ruby
Toon.encode({
  'items' => [1, { 'a' => 1 }, 'text']
})
```

```
items[3]:
  - 1
  - a: 1
  - text
```

### Delimiter Options

The `delimiter` option allows you to choose between comma (default), tab, or pipe delimiters:

```ruby
# Tab delimiter (can save additional tokens)
data = {
  'items' => [
    { 'sku' => 'A1', 'name' => 'Widget', 'qty' => 2 },
    { 'sku' => 'B2', 'name' => 'Gadget', 'qty' => 1 }
  ]
}

Toon.encode(data, delimiter: "\t")
```

Output:

```
items[2	]{sku	name	qty}:
  A1	Widget	2
  B2	Gadget	1
```

### Length Marker Option

The `length_marker` option adds a hash (`#`) prefix to array lengths:

```ruby
data = {
  'tags' => ['reading', 'gaming', 'coding'],
  'items' => [
    { 'sku' => 'A1', 'qty' => 2 },
    { 'sku' => 'B2', 'qty' => 1 }
  ]
}

Toon.encode(data, length_marker: '#')
```

Output:

```
tags[#3]: reading,gaming,coding
items[#2]{sku,qty}:
  A1,2
  B2,1
```

## Type Conversions

Some Ruby types are automatically normalized:

| Input | Output |
|---|---|
| `Symbol` | String (`:hello` → `"hello"`) |
| `Time`, `DateTime` | ISO8601 string |
| `Date` | ISO8601 string |
| `Float::INFINITY`, `Float::NAN` | `null` |
| `Set` | Array |

## Quoting Rules

TOON quotes strings **only when necessary** to maximize token efficiency:

- Empty strings are quoted: `""`
- Strings with leading/trailing spaces: `" padded "`
- Strings that look like booleans/numbers: `"true"`, `"42"`
- Strings with structural characters: `"a,b"`, `"a:b"`, `"[5]"`
- The active delimiter triggers quoting

Keys follow similar rules and are quoted when needed.

## Using TOON in LLM Prompts

When incorporating TOON into your LLM workflows:

- Wrap TOON data in a fenced code block in your prompt
- Tell the model: "Do not add extra punctuation or spaces; follow the exact TOON format."
- When asking the model to generate TOON, specify the same rules (2-space indentation, no trailing spaces, quoting rules)

## Notes and Limitations

- **Token counts vary by tokenizer and model.** Benchmarks use a GPT-style tokenizer; actual savings will differ with other models.
- **TOON is designed for LLM contexts** where human readability and token efficiency matter. It's **not** a drop-in replacement for JSON in APIs or storage.
- **Tabular arrays** require all objects to have exactly the same keys with primitive values only.
- **Object key order** is preserved from the input. In tabular arrays, header order follows the first object's keys.

## Development

After checking out the repo, run:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rspec
```

Or simply:

```bash
rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrepcg/toon-ruby.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Credits

This is a Ruby port of the original [TOON library](https://github.com/johannschopplich/toon) by [Johann Schopplich](https://github.com/johannschopplich).

