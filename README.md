# TOON for Ruby

[![Gem Version](https://badge.fury.io/rb/toon-ruby.svg)](https://badge.fury.io/rb/toon-ruby)
[![Build Status](https://github.com/andrepcg/toon-ruby/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/andrepcg/toon-ruby/actions/workflows/ci.yml)

**Token-Oriented Object Notation** is a compact, human-readable format designed for passing structured data to Large Language Models with significantly reduced token usage.

This is a Ruby port of the [TOON library](https://github.com/johannschopplich/toon) originally written in TypeScript.

TOON excels at **uniform complex objects** – multiple fields per row, same structure across items. It borrows YAML's indentation-based structure for nested objects and CSV's tabular format for uniform data rows, then optimizes both for token efficiency in LLM contexts.

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

## Format Comparison

Format familiarity matters as much as token count.

- **CSV:** best for uniform tables.
- **JSON:** best for non-uniform data.
- **TOON:** best for uniform complex (but not deeply nested) objects.

TOON switches to list format for non-uniform arrays. In those cases, JSON can be cheaper at scale.

## Key Features

- 💸 **Token-efficient:** typically 30–60% fewer tokens than JSON
- 🤿 **LLM-friendly guardrails:** explicit lengths and field lists help models validate output
- 🍱 **Minimal syntax:** removes redundant punctuation (braces, brackets, most quotes)
- 📐 **Indentation-based structure:** replaces braces with whitespace for better readability
- 🧺 **Tabular arrays:** declare keys once, then stream rows without repetition

## Benchmarks

### Token Efficiency

```
⭐ GitHub Repositories       ██████████████░░░░░░░░░░░   8,745 tokens
                             vs JSON: 15,145  💰 42.3% saved
                             vs XML:  17,095  💰 48.8% saved

📈 Daily Analytics           ██████████░░░░░░░░░░░░░░░   4,507 tokens
                             vs JSON: 10,977  💰 58.9% saved
                             vs XML:  13,128  💰 65.7% saved

🛒 E-Commerce Order          ████████████████░░░░░░░░░     166 tokens
                             vs JSON:    257  💰 35.4% saved
                             vs XML:     271  💰 38.7% saved

─────────────────────────────────────────────────────────────────────
Total                        ████████████░░░░░░░░░░░░░  13,418 tokens
                             vs JSON: 26,379  💰 49.1% saved
                             vs XML:  30,494  💰 56.0% saved
```

> **Note:** Measured with `gpt-tokenizer` using `o200k_base` encoding (used by GPT-5 and other modern models). Savings will vary across models and tokenizers.

### Retrieval Accuracy

Tested across **3 LLMs** with data retrieval tasks:

```
gpt-5-nano
  toon         ████████████████████  99.4% (158/159)
  yaml         ███████████████████░  95.0% (151/159)
  csv          ██████████████████░░  92.5% (147/159)
  json         ██████████████████░░  92.5% (147/159)
  xml          ██████████████████░░  91.2% (145/159)

claude-haiku-4-5
  toon         ███████████████░░░░░  75.5% (120/159)
  xml          ███████████████░░░░░  75.5% (120/159)
  csv          ███████████████░░░░░  75.5% (120/159)
  json         ███████████████░░░░░  75.5% (120/159)
  yaml         ███████████████░░░░░  74.2% (118/159)

gemini-2.5-flash
  xml          ██████████████████░░  91.8% (146/159)
  csv          █████████████████░░░  86.2% (137/159)
  toon         █████████████████░░░  84.9% (135/159)
  json         ████████████████░░░░  81.8% (130/159)
  yaml         ████████████████░░░░  78.6% (125/159)
```

**Advantage:** TOON achieves **86.6% accuracy** (vs JSON's 83.2%) while using **46.3% fewer tokens**.

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

## Canonical Formatting Rules

TOON formatting is deterministic and minimal:

- **Indentation**: 2 spaces per nesting level.
- **Lines**:
  - `key: value` for primitives (single space after colon).
  - `key:` for nested/empty objects (no trailing space on that line).
- **Arrays**:
  - Delimiter encoding: Comma delimiters are implicit in array headers (e.g., `tags[3]:`, `items[2]{id,name}:`). Tab and pipe delimiters are explicitly shown in array headers (e.g., `tags[3|]:`, `items[2	]{id	name}:`).
  - Primitive arrays inline: `key[N]: v1,v2` (comma) or `key[N<delim>]: v1<delim>v2` (tab/pipe).
  - Tabular arrays: `key[N]{f1,f2}: …` (comma) or `key[N<delim>]{f1<delim>f2}: …` (tab/pipe).
  - List items: two spaces, hyphen, space (`"  - …"`).
- **Whitespace invariants**:
  - No trailing spaces at end of any line.
  - No trailing newline at end of output.

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

> **Tip:** TOON includes the array length in brackets (e.g., `items[3]`). When using comma delimiters (default), the delimiter is implicit. When using tab or pipe delimiters, the delimiter is explicitly shown in the header (e.g., `tags[2|]` or `[2	]`). This encoding helps LLMs identify the delimiter and track the number of elements, reducing errors when generating or validating structured output.

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

**Tabular formatting applies recursively:** nested arrays of objects (whether as object properties or inside list items) also use tabular format if they meet the same requirements.

```ruby
Toon.encode({
  'items' => [
    {
      'users' => [
        { 'id' => 1, 'name' => 'Ada' },
        { 'id' => 2, 'name' => 'Bob' }
      ],
      'status' => 'active'
    }
  ]
})
```

```
items[1]:
  - users[2]{id,name}:
    1,Ada
    2,Bob
    status: active
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

When objects appear in list format, the first field is placed on the hyphen line:

```
items[2]:
  - id: 1
    name: First
  - id: 2
    name: Second
    extra: true
```

> **Note:** **Nested array indentation:** When the first field of a list item is an array (primitive, tabular, or nested), its contents are indented two spaces under the header line, and subsequent fields of the same object appear at that same indentation level. This remains unambiguous because list items begin with `"- "`, tabular arrays declare a fixed row count in their header, and object fields contain `":"`.

#### Arrays of Arrays

When you have arrays containing primitive inner arrays:

```ruby
Toon.encode({
  'pairs' => [
    [1, 2],
    [3, 4]
  ]
})
```

```
pairs[2]:
  - [2]: 1,2
  - [2]: 3,4
```

#### Empty Arrays and Objects

Empty containers have special representations:

```ruby
Toon.encode({ 'items' => [] }) # items[0]:
Toon.encode([])                # [0]:
Toon.encode({})                # (empty output)
Toon.encode({ 'config' => {} }) # config:
```

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
Toon.encode({ 'items' => items }, delimiter: "\t")
# => "items[2	]{sku	qty	price}:\n  A1\t2\t9.99\n  B2\t1\t14.5"

# Length marker
Toon.encode({ 'tags' => ['a', 'b', 'c'] }, length_marker: '#')
# => "tags[#3]: a,b,c"
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

**Benefits:**

- Tabs are single characters and often tokenize more efficiently than commas.
- Tabs rarely appear in natural text, reducing the need for quote-escaping.
- The delimiter is explicitly encoded in the array header, making it self-descriptive.

**Considerations:**

- Some terminals and editors may collapse or expand tabs visually.
- String values containing tabs will still require quoting.

#### Pipe Delimiter (`|`)

Pipe delimiters offer a middle ground between commas and tabs:

```ruby
Toon.encode(data, delimiter: '|')
```

Output:

```
items[2|]{sku|name|qty}:
  A1|Widget|2
  B2|Gadget|1
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

## Quoting Rules

TOON quotes strings **only when necessary** to maximize token efficiency. Inner spaces are allowed; leading or trailing spaces force quotes. Unicode and emoji are safe unquoted.

> **Note:** When using alternative delimiters (tab or pipe), the quoting rules adapt automatically. Strings containing the active delimiter will be quoted, while other delimiters remain safe.

### Keys

Keys are quoted when any of the following is true:

| Condition | Examples |
|---|---|
| Contains spaces, commas, colons, quotes, control chars | `"full name"`, `"a,b"`, `"order:id"`, `"tab\there"` |
| Contains brackets or braces | `"[index]"`, `"{key}"` |
| Leading hyphen | `"-lead"` |
| Numeric-only key | `"123"` |
| Empty key | `""` |

**Notes:**

- Quotes and control characters in keys are escaped (e.g., `"he said \"hi\""`, `"line\nbreak"`).

### String Values

String values are quoted when any of the following is true:

| Condition | Examples |
|---|---|
| Empty string | `""` |
| Contains active delimiter, colon, quote, backslash, or control chars | `"a,b"` (comma), `"a\tb"` (tab), `"a\|b"` (pipe), `"a:b"`, `"say \"hi\""`, `"C:\\Users"`, `"line1\\nline2"` |
| Leading or trailing spaces | `" padded "`, `"  "` |
| Looks like boolean/number/null | `"true"`, `"false"`, `"null"`, `"42"`, `"-3.14"`, `"1e-6"`, `"05"` |
| Starts with `"- "` (list-like) | `"- item"` |
| Looks like structural token | `"[5]"`, `"{key}"`, `"[3]: x,y"` |

> **Important:** **Delimiter-aware quoting:** Unquoted strings never contain `:` or the active delimiter. This makes TOON reliably parseable with simple heuristics: split key/value on first `: `, and split array values on the delimiter declared in the array header. When using tab or pipe delimiters, commas don't need quoting – only the active delimiter triggers quoting for both array values and object values.

### Examples

```
note: "hello, world"
items[3]: foo,"true","- item"
hello 👋 world         // unquoted
" padded "             // quoted
value: null            // null value
name: ""               // empty string (quoted)
text: "line1\nline2"   // multi-line string (escaped)
```

## Tabular Format Requirements

For arrays of objects to use the efficient tabular format, all of the following must be true:

| Requirement | Detail |
|---|---|
| All elements are objects | No primitives in the array |
| Identical key sets | No missing or extra keys across rows |
| Primitive values only | No nested arrays or objects |
| Header delimiter | Comma is implicit in headers (`[N]{f1,f2}`); tab and pipe are explicit (`[N	]{f1	f2}`, `[N|]{f1|f2}`) |
| Header key order | Taken from the first object |
| Header key quoting | Same rules as object keys; keys containing the active delimiter must be quoted |
| Row value quoting | Same rules as string values; values containing the active delimiter must be quoted |

If any condition fails, TOON falls back to list format.

## Type Conversions

Some Ruby types are automatically normalized:

| Input | Output |
|---|---|
| `Symbol` | String (`:hello` → `"hello"`) |
| `Time`, `DateTime` | ISO8601 string |
| `Date` | ISO8601 string |
| `Float::INFINITY`, `Float::NAN` | `null` |
| `Set` | Array |

## Using TOON in LLM Prompts

TOON works best when you show the format instead of describing it. The structure is self-documenting – models parse it naturally once they see the pattern.

### Sending TOON to LLMs (Input)

Wrap your encoded data in a fenced code block (label it \`\`\`toon for clarity). The indentation and headers are usually enough – models treat it like familiar YAML or CSV. The explicit length markers (`[N]`) and field headers (`{field1,field2}`) help the model track structure, especially for large tables.

### Generating TOON from LLMs (Output)

For output, be more explicit. When you want the model to **generate** TOON:

- **Show the expected header** (`users[N]{id,name,role}:`). The model fills rows instead of repeating keys, reducing generation errors.
- **State the rules**: 2-space indent, no trailing spaces, `[N]` matches row count.

Here's a prompt that works for both reading and generating:

```
Data is in TOON format (2-space indent, arrays show length and fields).

\```toon
users[3]{id,name,role,lastLogin}:
  1,Alice,admin,2025-01-15T10:30:00Z
  2,Bob,user,2025-01-14T15:22:00Z
  3,Charlie,user,2025-01-13T09:45:00Z
\```

Task: Return only users with role "user" as TOON. Use the same header. Set [N] to match the row count. Output only the code block.
```

> **Tip:** For large uniform tables, use `Toon.encode(data, delimiter: "\t")` and tell the model "fields are tab-separated." Tabs often tokenize better than commas and reduce the need for quote-escaping.

## Notes and Limitations

- **Token counts vary by tokenizer and model.** Benchmarks use a GPT-style tokenizer; actual savings will differ with other models.
- **TOON is designed for LLM contexts** where human readability and token efficiency matter. It's **not** a drop-in replacement for JSON in APIs or storage.
- **Tabular arrays** require all objects to have exactly the same keys with primitive values only.
- **Object key order** is preserved from the input. In tabular arrays, header order follows the first object's keys.

## Quick Reference

```
// Object
{ id: 1, name: 'Ada' }          → id: 1
                                  name: Ada

// Nested object
{ user: { id: 1 } }             → user:
                                    id: 1

// Primitive array (inline)
{ tags: ['foo', 'bar'] }        → tags[2]: foo,bar

// Tabular array (uniform objects)
{ items: [                      → items[2]{id,qty}:
  { id: 1, qty: 5 },                1,5
  { id: 2, qty: 3 }                 2,3
]}

// Mixed / non-uniform (list)
{ items: [1, { a: 1 }, 'x'] }   → items[3]:
                                    - 1
                                    - a: 1
                                    - x

// Array of arrays
{ pairs: [[1, 2], [3, 4]] }     → pairs[2]:
                                    - [2]: 1,2
                                    - [2]: 3,4

// Root array
['x', 'y']                      → [2]: x,y

// Empty containers
{}                              → (empty output)
{ items: [] }                   → items[0]:

// Special quoting
{ note: 'hello, world' }        → note: "hello, world"
{ items: ['true', true] }       → items[2]: "true",true
```

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
```
