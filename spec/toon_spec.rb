# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Toon do
  describe 'primitives' do
    it 'encodes safe strings without quotes' do
      expect(Toon.encode('hello')).to eq('hello')
      expect(Toon.encode('Ada_99')).to eq('Ada_99')
    end

    it 'quotes empty string' do
      expect(Toon.encode('')).to eq('""')
    end

    it 'quotes strings that look like booleans or numbers' do
      expect(Toon.encode('true')).to eq('"true"')
      expect(Toon.encode('false')).to eq('"false"')
      expect(Toon.encode('null')).to eq('"null"')
      expect(Toon.encode('42')).to eq('"42"')
      expect(Toon.encode('-3.14')).to eq('"-3.14"')
      expect(Toon.encode('1e-6')).to eq('"1e-6"')
      expect(Toon.encode('05')).to eq('"05"')
    end

    it 'escapes control characters in strings' do
      expect(Toon.encode("line1\nline2")).to eq('"line1\nline2"')
      expect(Toon.encode("tab\there")).to eq('"tab\there"')
      expect(Toon.encode("return\rcarriage")).to eq('"return\rcarriage"')
      expect(Toon.encode('C:\Users\path')).to eq('"C:\\Users\\path"')
    end

    it 'quotes strings with structural characters' do
      expect(Toon.encode('[3]: x,y')).to eq('"[3]: x,y"')
      expect(Toon.encode('- item')).to eq('"- item"')
      expect(Toon.encode('[test]')).to eq('"[test]"')
      expect(Toon.encode('{key}')).to eq('"{key}"')
    end

    it 'handles Unicode and emoji' do
      expect(Toon.encode('café')).to eq('café')
      expect(Toon.encode('你好')).to eq('你好')
      expect(Toon.encode('🚀')).to eq('🚀')
      expect(Toon.encode('hello 👋 world')).to eq('hello 👋 world')
    end

    it 'encodes numbers' do
      expect(Toon.encode(42)).to eq('42')
      expect(Toon.encode(3.14)).to eq('3.14')
      expect(Toon.encode(-7)).to eq('-7')
      expect(Toon.encode(0)).to eq('0')
    end

    it 'handles special numeric values' do
      expect(Toon.encode(-0.0)).to eq('0')
      expect(Toon.encode(1e6)).to eq('1000000.0')
      expect(Toon.encode(1e-6)).to eq('1.0e-06')
    end

    it 'encodes booleans' do
      expect(Toon.encode(true)).to eq('true')
      expect(Toon.encode(false)).to eq('false')
    end

    it 'encodes null' do
      expect(Toon.encode(nil)).to eq('null')
    end
  end

  describe 'objects (simple)' do
    it 'preserves key order in objects' do
      obj = {
        'id' => 123,
        'name' => 'Ada',
        'active' => true
      }
      expect(Toon.encode(obj)).to eq("id: 123\nname: Ada\nactive: true")
    end

    it 'encodes null values in objects' do
      obj = { 'id' => 123, 'value' => nil }
      expect(Toon.encode(obj)).to eq("id: 123\nvalue: null")
    end

    it 'encodes empty objects as empty string' do
      expect(Toon.encode({})).to eq('')
    end

    it 'quotes string values with special characters' do
      expect(Toon.encode({ 'note' => 'a:b' })).to eq('note: "a:b"')
      expect(Toon.encode({ 'note' => 'a,b' })).to eq('note: "a,b"')
      expect(Toon.encode({ 'text' => "line1\nline2" })).to eq('text: "line1\nline2"')
      expect(Toon.encode({ 'text' => 'say "hello"' })).to eq('text: "say \"hello\""')
    end

    it 'quotes string values with leading/trailing spaces' do
      expect(Toon.encode({ 'text' => ' padded ' })).to eq('text: " padded "')
      expect(Toon.encode({ 'text' => '  ' })).to eq('text: "  "')
    end

    it 'quotes string values that look like booleans/numbers' do
      expect(Toon.encode({ 'v' => 'true' })).to eq('v: "true"')
      expect(Toon.encode({ 'v' => '42' })).to eq('v: "42"')
      expect(Toon.encode({ 'v' => '-7.5' })).to eq('v: "-7.5"')
    end
  end

  describe 'objects (keys)' do
    it 'quotes keys with special characters' do
      expect(Toon.encode({ 'order:id' => 7 })).to eq('"order:id": 7')
      expect(Toon.encode({ '[index]' => 5 })).to eq('"[index]": 5')
      expect(Toon.encode({ '{key}' => 5 })).to eq('"{key}": 5')
      expect(Toon.encode({ 'a,b' => 1 })).to eq('"a,b": 1')
    end

    it 'quotes keys with spaces or leading hyphens' do
      expect(Toon.encode({ 'full name' => 'Ada' })).to eq('"full name": Ada')
      expect(Toon.encode({ '-lead' => 1 })).to eq('"-lead": 1')
      expect(Toon.encode({ ' a ' => 1 })).to eq('" a ": 1')
    end

    it 'quotes numeric keys' do
      expect(Toon.encode({ '123' => 'x' })).to eq('"123": x')
    end

    it 'quotes empty string key' do
      expect(Toon.encode({ '' => 1 })).to eq('"": 1')
    end

    it 'escapes control characters in keys' do
      expect(Toon.encode({ "line\nbreak" => 1 })).to eq('"line\nbreak": 1')
      expect(Toon.encode({ "tab\there" => 2 })).to eq('"tab\there": 2')
    end

    it 'escapes quotes in keys' do
      expect(Toon.encode({ 'he said "hi"' => 1 })).to eq('"he said \"hi\"": 1')
    end
  end

  describe 'nested objects' do
    it 'encodes deeply nested objects' do
      obj = {
        'a' => {
          'b' => {
            'c' => 'deep'
          }
        }
      }
      expect(Toon.encode(obj)).to eq("a:\n  b:\n    c: deep")
    end

    it 'encodes empty nested object' do
      expect(Toon.encode({ 'user' => {} })).to eq('user:')
    end
  end

  describe 'arrays of primitives' do
    it 'encodes string arrays inline' do
      obj = { 'tags' => ['reading', 'gaming'] }
      expect(Toon.encode(obj)).to eq('tags[2]: reading,gaming')
    end

    it 'encodes number arrays inline' do
      obj = { 'nums' => [1, 2, 3] }
      expect(Toon.encode(obj)).to eq('nums[3]: 1,2,3')
    end

    it 'encodes mixed primitive arrays inline' do
      obj = { 'data' => ['x', 'y', true, 10] }
      expect(Toon.encode(obj)).to eq('data[4]: x,y,true,10')
    end

    it 'encodes empty arrays' do
      obj = { 'items' => [] }
      expect(Toon.encode(obj)).to eq('items[0]:')
    end

    it 'handles empty string in arrays' do
      obj = { 'items' => [''] }
      expect(Toon.encode(obj)).to eq('items[1]: ""')
      obj2 = { 'items' => ['a', '', 'b'] }
      expect(Toon.encode(obj2)).to eq('items[3]: a,"",b')
    end

    it 'handles whitespace-only strings in arrays' do
      obj = { 'items' => [' ', '  '] }
      expect(Toon.encode(obj)).to eq('items[2]: " ","  "')
    end

    it 'quotes array strings with special characters' do
      obj = { 'items' => ['a', 'b,c', 'd:e'] }
      expect(Toon.encode(obj)).to eq('items[3]: a,"b,c","d:e"')
    end

    it 'quotes strings that look like booleans/numbers in arrays' do
      obj = { 'items' => ['x', 'true', '42', '-3.14'] }
      expect(Toon.encode(obj)).to eq('items[4]: x,"true","42","-3.14"')
    end

    it 'quotes strings with structural meanings in arrays' do
      obj = { 'items' => ['[5]', '- item', '{key}'] }
      expect(Toon.encode(obj)).to eq('items[3]: "[5]","- item","{key}"')
    end
  end

  describe 'arrays of objects (tabular and list items)' do
    it 'encodes arrays of similar objects in tabular format' do
      obj = {
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5")
    end

    it 'handles null values in tabular format' do
      obj = {
        'items' => [
          { 'id' => 1, 'value' => nil },
          { 'id' => 2, 'value' => 'test' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{id,value}:\n  1,null\n  2,test")
    end

    it 'quotes strings containing delimiters in tabular rows' do
      obj = {
        'items' => [
          { 'sku' => 'A,1', 'desc' => 'cool', 'qty' => 2 },
          { 'sku' => 'B2', 'desc' => 'wip: test', 'qty' => 1 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{sku,desc,qty}:\n  \"A,1\",cool,2\n  B2,\"wip: test\",1")
    end

    it 'quotes ambiguous strings in tabular rows' do
      obj = {
        'items' => [
          { 'id' => 1, 'status' => 'true' },
          { 'id' => 2, 'status' => 'false' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{id,status}:\n  1,\"true\"\n  2,\"false\"")
    end

    it 'handles tabular arrays with keys needing quotes' do
      obj = {
        'items' => [
          { 'order:id' => 1, 'full name' => 'Ada' },
          { 'order:id' => 2, 'full name' => 'Bob' }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{\"order:id\",\"full name\"}:\n  1,Ada\n  2,Bob")
    end

    it 'uses list format for objects with different fields' do
      obj = {
        'items' => [
          { 'id' => 1, 'name' => 'First' },
          { 'id' => 2, 'name' => 'Second', 'extra' => true }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - id: 1\n" \
        "    name: First\n" \
        "  - id: 2\n" \
        "    name: Second\n" \
        "    extra: true"
      )
    end

    it 'uses list format for objects with nested values' do
      obj = {
        'items' => [
          { 'id' => 1, 'nested' => { 'x' => 1 } }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - id: 1\n" \
        "    nested:\n" \
        "      x: 1"
      )
    end

    it 'preserves field order in list items' do
      obj = { 'items' => [{ 'nums' => [1, 2, 3], 'name' => 'test' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[3]: 1,2,3\n" \
        "    name: test"
      )
    end

    it 'preserves field order when primitive appears first' do
      obj = { 'items' => [{ 'name' => 'test', 'nums' => [1, 2, 3] }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - name: test\n" \
        "    nums[3]: 1,2,3"
      )
    end

    it 'uses list format for objects containing arrays of arrays' do
      obj = {
        'items' => [
          { 'matrix' => [[1, 2], [3, 4]], 'name' => 'grid' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - matrix[2]:\n" \
        "    - [2]: 1,2\n" \
        "    - [2]: 3,4\n" \
        "    name: grid"
      )
    end

    it 'uses tabular format for nested uniform object arrays' do
      obj = {
        'items' => [
          { 'users' => [{ 'id' => 1, 'name' => 'Ada' }, { 'id' => 2, 'name' => 'Bob' }], 'status' => 'active' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]{id,name}:\n" \
        "    1,Ada\n" \
        "    2,Bob\n" \
        "    status: active"
      )
    end

    it 'uses list format for nested object arrays with mismatched keys' do
      obj = {
        'items' => [
          { 'users' => [{ 'id' => 1, 'name' => 'Ada' }, { 'id' => 2 }], 'status' => 'active' }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]:\n" \
        "    - id: 1\n" \
        "      name: Ada\n" \
        "    - id: 2\n" \
        "    status: active"
      )
    end

    it 'uses list format for objects with multiple array fields' do
      obj = { 'items' => [{ 'nums' => [1, 2], 'tags' => ['a', 'b'], 'name' => 'test' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[2]: 1,2\n" \
        "    tags[2]: a,b\n" \
        "    name: test"
      )
    end

    it 'uses list format for objects with only array fields' do
      obj = { 'items' => [{ 'nums' => [1, 2, 3], 'tags' => ['a', 'b'] }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - nums[3]: 1,2,3\n" \
        "    tags[2]: a,b"
      )
    end

    it 'handles objects with empty arrays in list format' do
      obj = {
        'items' => [
          { 'name' => 'test', 'data' => [] }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - name: test\n" \
        "    data[0]:"
      )
    end

    it 'places first field of nested tabular arrays on hyphen line' do
      obj = { 'items' => [{ 'users' => [{ 'id' => 1 }, { 'id' => 2 }], 'note' => 'x' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - users[2]{id}:\n" \
        "    1\n" \
        "    2\n" \
        "    note: x"
      )
    end

    it 'places empty arrays on hyphen line when first' do
      obj = { 'items' => [{ 'data' => [], 'name' => 'x' }] }
      expect(Toon.encode(obj)).to eq(
        "items[1]:\n" \
        "  - data[0]:\n" \
        "    name: x"
      )
    end

    it 'uses field order from first object for tabular headers' do
      obj = {
        'items' => [
          { 'a' => 1, 'b' => 2, 'c' => 3 },
          { 'c' => 30, 'b' => 20, 'a' => 10 }
        ]
      }
      expect(Toon.encode(obj)).to eq("items[2]{a,b,c}:\n  1,2,3\n  10,20,30")
    end

    it 'uses list format for one object with nested column' do
      obj = {
        'items' => [
          { 'id' => 1, 'data' => 'string' },
          { 'id' => 2, 'data' => { 'nested' => true } }
        ]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - id: 1\n" \
        "    data: string\n" \
        "  - id: 2\n" \
        "    data:\n" \
        "      nested: true"
      )
    end
  end

  describe 'arrays of arrays (primitives only)' do
    it 'encodes nested arrays of primitives' do
      obj = {
        'pairs' => [['a', 'b'], ['c', 'd']]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [2]: a,b\n  - [2]: c,d")
    end

    it 'quotes strings containing delimiters in nested arrays' do
      obj = {
        'pairs' => [['a', 'b'], ['c,d', 'e:f', 'true']]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [2]: a,b\n  - [3]: \"c,d\",\"e:f\",\"true\"")
    end

    it 'handles empty inner arrays' do
      obj = {
        'pairs' => [[], []]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [0]:\n  - [0]:")
    end

    it 'handles mixed-length inner arrays' do
      obj = {
        'pairs' => [[1], [2, 3]]
      }
      expect(Toon.encode(obj)).to eq("pairs[2]:\n  - [1]: 1\n  - [2]: 2,3")
    end
  end

  describe 'root arrays' do
    it 'encodes arrays of primitives at root level' do
      arr = ['x', 'y', 'true', true, 10]
      expect(Toon.encode(arr)).to eq('[5]: x,y,"true",true,10')
    end

    it 'encodes arrays of similar objects in tabular format' do
      arr = [{ 'id' => 1 }, { 'id' => 2 }]
      expect(Toon.encode(arr)).to eq("[2]{id}:\n  1\n  2")
    end

    it 'encodes arrays of different objects in list format' do
      arr = [{ 'id' => 1 }, { 'id' => 2, 'name' => 'Ada' }]
      expect(Toon.encode(arr)).to eq("[2]:\n  - id: 1\n  - id: 2\n    name: Ada")
    end

    it 'encodes empty arrays at root level' do
      expect(Toon.encode([])).to eq('[0]:')
    end

    it 'encodes arrays of arrays at root level' do
      arr = [[1, 2], []]
      expect(Toon.encode(arr)).to eq("[2]:\n  - [2]: 1,2\n  - [0]:")
    end
  end

  describe 'complex structures' do
    it 'encodes objects with mixed arrays and nested objects' do
      obj = {
        'user' => {
          'id' => 123,
          'name' => 'Ada',
          'tags' => ['reading', 'gaming'],
          'active' => true,
          'prefs' => []
        }
      }
      expect(Toon.encode(obj)).to eq(
        "user:\n" \
        "  id: 123\n" \
        "  name: Ada\n" \
        "  tags[2]: reading,gaming\n" \
        "  active: true\n" \
        "  prefs[0]:"
      )
    end
  end

  describe 'mixed arrays' do
    it 'uses list format for arrays mixing primitives and objects' do
      obj = {
        'items' => [1, { 'a' => 1 }, 'text']
      }
      expect(Toon.encode(obj)).to eq(
        "items[3]:\n" \
        "  - 1\n" \
        "  - a: 1\n" \
        "  - text"
      )
    end

    it 'uses list format for arrays mixing objects and arrays' do
      obj = {
        'items' => [{ 'a' => 1 }, [1, 2]]
      }
      expect(Toon.encode(obj)).to eq(
        "items[2]:\n" \
        "  - a: 1\n" \
        "  - [2]: 1,2"
      )
    end
  end

  describe 'whitespace and formatting invariants' do
    it 'produces no trailing spaces at end of lines' do
      obj = {
        'user' => {
          'id' => 123,
          'name' => 'Ada'
        },
        'items' => ['a', 'b']
      }
      result = Toon.encode(obj)
      lines = result.split("\n")
      lines.each do |line|
        expect(line).not_to match(/ $/)
      end
    end

    it 'produces no trailing newline at end of output' do
      obj = { 'id' => 123 }
      result = Toon.encode(obj)
      expect(result).not_to match(/\n$/)
    end
  end

  describe 'non-JSON-serializable values' do
    it 'converts Symbol to string' do
      expect(Toon.encode(:hello)).to eq('hello')
      expect(Toon.encode({ id: 456 })).to eq('id: 456')
    end

    it 'converts Time to ISO string' do
      time = Time.utc(2025, 1, 1, 0, 0, 0)
      expect(Toon.encode(time)).to eq('"2025-01-01T00:00:00Z"')
      expect(Toon.encode({ created: time })).to eq('created: "2025-01-01T00:00:00Z"')
    end

    it 'converts non-finite numbers to null' do
      expect(Toon.encode(Float::INFINITY)).to eq('null')
      expect(Toon.encode(-Float::INFINITY)).to eq('null')
      expect(Toon.encode(Float::NAN)).to eq('null')
    end
  end

  describe 'delimiter options' do
    describe 'basic delimiter usage' do
      [
        { delimiter: "\t", name: 'tab', expected: "reading\tgaming\tcoding" },
        { delimiter: '|', name: 'pipe', expected: 'reading|gaming|coding' },
        { delimiter: ',', name: 'comma', expected: 'reading,gaming,coding' }
      ].each do |test_case|
        it "encodes primitive arrays with #{test_case[:name]}" do
          obj = { 'tags' => ['reading', 'gaming', 'coding'] }
          delimiter_suffix = test_case[:delimiter] != ',' ? test_case[:delimiter] : ''
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq("tags[3#{delimiter_suffix}]: #{test_case[:expected]}")
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "items[2\t]{sku\tqty\tprice}:\n  A1\t2\t9.99\n  B2\t1\t14.5" },
        { delimiter: '|', name: 'pipe', expected: "items[2|]{sku|qty|price}:\n  A1|2|9.99\n  B2|1|14.5" }
      ].each do |test_case|
        it "encodes tabular arrays with #{test_case[:name]}" do
          obj = {
            'items' => [
              { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
              { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
            ]
          }
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "pairs[2\t]:\n  - [2\t]: a\tb\n  - [2\t]: c\td" },
        { delimiter: '|', name: 'pipe', expected: "pairs[2|]:\n  - [2|]: a|b\n  - [2|]: c|d" }
      ].each do |test_case|
        it "encodes nested arrays with #{test_case[:name]}" do
          obj = { 'pairs' => [['a', 'b'], ['c', 'd']] }
          expect(Toon.encode(obj, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end

      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "encodes root arrays with #{test_case[:name]}" do
          arr = ['x', 'y', 'z']
          expect(Toon.encode(arr, delimiter: test_case[:delimiter])).to eq("[3#{test_case[:delimiter]}]: x#{test_case[:delimiter]}y#{test_case[:delimiter]}z")
        end
      end

      [
        { delimiter: "\t", name: 'tab', expected: "[2\t]{id}:\n  1\n  2" },
        { delimiter: '|', name: 'pipe', expected: "[2|]{id}:\n  1\n  2" }
      ].each do |test_case|
        it "encodes root arrays of objects with #{test_case[:name]}" do
          arr = [{ 'id' => 1 }, { 'id' => 2 }]
          expect(Toon.encode(arr, delimiter: test_case[:delimiter])).to eq(test_case[:expected])
        end
      end
    end

    describe 'delimiter-aware quoting' do
      [
        { delimiter: "\t", name: 'tab', char: "\t", input: ['a', "b\tc", 'd'], expected: "a\t\"b\\tc\"\td" },
        { delimiter: '|', name: 'pipe', char: '|', input: ['a', 'b|c', 'd'], expected: 'a|"b|c"|d' }
      ].each do |test_case|
        it "quotes strings containing #{test_case[:name]}" do
          expect(Toon.encode({ 'items' => test_case[:input] }, delimiter: test_case[:delimiter])).to eq("items[#{test_case[:input].length}#{test_case[:delimiter]}]: #{test_case[:expected]}")
        end
      end

      [
        { delimiter: "\t", name: 'tab', input: ['a,b', 'c,d'], expected: "a,b\tc,d" },
        { delimiter: '|', name: 'pipe', input: ['a,b', 'c,d'], expected: 'a,b|c,d' }
      ].each do |test_case|
        it "does not quote commas with #{test_case[:name]}" do
          expect(Toon.encode({ 'items' => test_case[:input] }, delimiter: test_case[:delimiter])).to eq("items[#{test_case[:input].length}#{test_case[:delimiter]}]: #{test_case[:expected]}")
        end
      end

      it 'quotes tabular values containing the delimiter' do
        obj = {
          'items' => [
            { 'id' => 1, 'note' => 'a,b' },
            { 'id' => 2, 'note' => 'c,d' }
          ]
        }
        expect(Toon.encode(obj, delimiter: ',')).to eq("items[2]{id,note}:\n  1,\"a,b\"\n  2,\"c,d\"")
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[2\t]{id\tnote}:\n  1\ta,b\n  2\tc,d")
      end

      it 'does not quote commas in object values with non-comma delimiter' do
        expect(Toon.encode({ 'note' => 'a,b' }, delimiter: '|')).to eq('note: a,b')
        expect(Toon.encode({ 'note' => 'a,b' }, delimiter: "\t")).to eq('note: a,b')
      end

      it 'quotes nested array values containing the delimiter' do
        expect(Toon.encode({ 'pairs' => [['a', 'b|c']] }, delimiter: '|')).to eq("pairs[1|]:\n  - [2|]: a|\"b|c\"")
        expect(Toon.encode({ 'pairs' => [['a', "b\tc"]] }, delimiter: "\t")).to eq("pairs[1\t]:\n  - [2\t]: a\t\"b\\tc\"")
      end
    end

    describe 'delimiter-independent quoting rules' do
      it 'preserves ambiguity quoting regardless of delimiter' do
        obj = { 'items' => ['true', '42', '-3.14'] }
        expect(Toon.encode(obj, delimiter: '|')).to eq('items[3|]: "true"|"42"|"-3.14"')
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[3\t]: \"true\"\t\"42\"\t\"-3.14\"")
      end

      it 'preserves structural quoting regardless of delimiter' do
        obj = { 'items' => ['[5]', '{key}', '- item'] }
        expect(Toon.encode(obj, delimiter: '|')).to eq('items[3|]: "[5]"|"{key}"|"- item"')
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[3\t]: \"[5]\"\t\"{key}\"\t\"- item\"")
      end

      it 'quotes keys containing the delimiter' do
        expect(Toon.encode({ 'a|b' => 1 }, delimiter: '|')).to eq('"a|b": 1')
        expect(Toon.encode({ "a\tb" => 1 }, delimiter: "\t")).to eq("\"a\\tb\": 1")
      end

      it 'quotes tabular headers containing the delimiter' do
        obj = { 'items' => [{ 'a|b' => 1 }, { 'a|b' => 2 }] }
        expect(Toon.encode(obj, delimiter: '|')).to eq("items[2|]{\"a|b\"}:\n  1\n  2")
      end

      it 'header uses the active delimiter' do
        obj = { 'items' => [{ 'a' => 1, 'b' => 2 }, { 'a' => 3, 'b' => 4 }] }
        expect(Toon.encode(obj, delimiter: '|')).to eq("items[2|]{a|b}:\n  1|2\n  3|4")
        expect(Toon.encode(obj, delimiter: "\t")).to eq("items[2\t]{a\tb}:\n  1\t2\n  3\t4")
      end
    end

    describe 'formatting invariants with delimiters' do
      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "produces no trailing spaces with #{test_case[:name]}" do
          obj = {
            'user' => { 'id' => 123, 'name' => 'Ada' },
            'items' => ['a', 'b']
          }
          result = Toon.encode(obj, delimiter: test_case[:delimiter])
          lines = result.split("\n")
          lines.each do |line|
            expect(line).not_to match(/ $/)
          end
        end
      end

      [
        { delimiter: "\t", name: 'tab' },
        { delimiter: '|', name: 'pipe' }
      ].each do |test_case|
        it "produces no trailing newline with #{test_case[:name]}" do
          obj = { 'id' => 123 }
          result = Toon.encode(obj, delimiter: test_case[:delimiter])
          expect(result).not_to match(/\n$/)
        end
      end
    end
  end

  describe 'length marker option' do
    it 'adds length marker to primitive arrays' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj, length_marker: '#')).to eq('tags[#3]: reading,gaming,coding')
    end

    it 'handles empty arrays' do
      expect(Toon.encode({ 'items' => [] }, length_marker: '#')).to eq('items[#0]:')
    end

    it 'adds length marker to tabular arrays' do
      obj = {
        'items' => [
          { 'sku' => 'A1', 'qty' => 2, 'price' => 9.99 },
          { 'sku' => 'B2', 'qty' => 1, 'price' => 14.5 }
        ]
      }
      expect(Toon.encode(obj, length_marker: '#')).to eq("items[#2]{sku,qty,price}:\n  A1,2,9.99\n  B2,1,14.5")
    end

    it 'adds length marker to nested arrays' do
      obj = { 'pairs' => [['a', 'b'], ['c', 'd']] }
      expect(Toon.encode(obj, length_marker: '#')).to eq("pairs[#2]:\n  - [#2]: a,b\n  - [#2]: c,d")
    end

    it 'works with delimiter option' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj, length_marker: '#', delimiter: '|')).to eq('tags[#3|]: reading|gaming|coding')
    end

    it 'default is false (no length marker)' do
      obj = { 'tags' => ['reading', 'gaming', 'coding'] }
      expect(Toon.encode(obj)).to eq('tags[3]: reading,gaming,coding')
    end
  end

  describe 'output option' do
    let :obj do
      { 'hello' => '世界' }
    end

    it 'can encode lines to IO interface object' do
      output = StringIO.new
      expect(Toon.encode(obj, output: output)).to be_nil
      expect(output.string).to eq "hello: 世界"
    end

    it 'can encode with return value' do
      expect(Toon.encode(obj)).to eq 'hello: 世界'
    end
  end
end
