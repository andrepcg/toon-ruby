# frozen_string_literal: true

require_relative 'constants'
require_relative 'writer'
require_relative 'normalizer'
require_relative 'primitives'

module Toon
  module Encoders
    module_function

    extend Normalizer
    extend Primitives

    # Encode normalized value
    def encode_value(value, options)
      if json_primitive?(value)
        return encode_primitive(value, options[:delimiter])
      end

      writer = LineWriter.new(options[:indent])

      if json_array?(value)
        encode_array(nil, value, writer, 0, options)
      elsif json_object?(value)
        encode_object(value, writer, 0, options)
      end

      writer.to_s
    end

    # Object encoding
    def encode_object(value, writer, depth, options)
      keys = value.keys

      keys.each do |key|
        encode_key_value_pair(key, value[key], writer, depth, options)
      end
    end

    def encode_key_value_pair(key, value, writer, depth, options)
      encoded_key = encode_key(key)

      if json_primitive?(value)
        writer.push(depth, "#{encoded_key}: #{encode_primitive(value, options[:delimiter])}")
      elsif json_array?(value)
        encode_array(key, value, writer, depth, options)
      elsif json_object?(value)
        nested_keys = value.keys
        if nested_keys.empty?
          # Empty object
          writer.push(depth, "#{encoded_key}:")
        else
          writer.push(depth, "#{encoded_key}:")
          encode_object(value, writer, depth + 1, options)
        end
      end
    end

    # Array encoding
    def encode_array(key, value, writer, depth, options)
      if value.empty?
        header = format_header(0, key: key, delimiter: options[:delimiter], length_marker: options[:length_marker])
        writer.push(depth, header)
        return
      end

      # Primitive array
      if array_of_primitives?(value)
        encode_inline_primitive_array(key, value, writer, depth, options)
        return
      end

      # Array of arrays (all primitives)
      if array_of_arrays?(value)
        all_primitive_arrays = value.all? { |arr| array_of_primitives?(arr) }
        if all_primitive_arrays
          encode_array_of_arrays_as_list_items(key, value, writer, depth, options)
          return
        end
      end

      # Array of objects
      if array_of_objects?(value)
        header = detect_tabular_header(value)
        if header
          encode_array_of_objects_as_tabular(key, value, header, writer, depth, options)
        else
          encode_mixed_array_as_list_items(key, value, writer, depth, options)
        end
        return
      end

      # Mixed array: fallback to expanded format
      encode_mixed_array_as_list_items(key, value, writer, depth, options)
    end

    # Primitive array encoding (inline)
    def encode_inline_primitive_array(prefix, values, writer, depth, options)
      formatted = format_inline_array(values, options[:delimiter], prefix, options[:length_marker])
      writer.push(depth, formatted)
    end

    # Array of arrays (expanded format)
    def encode_array_of_arrays_as_list_items(prefix, values, writer, depth, options)
      header = format_header(values.length, key: prefix, delimiter: options[:delimiter], length_marker: options[:length_marker])
      writer.push(depth, header)

      values.each do |arr|
        if array_of_primitives?(arr)
          inline = format_inline_array(arr, options[:delimiter], nil, options[:length_marker])
          writer.push(depth + 1, "#{LIST_ITEM_PREFIX}#{inline}")
        end
      end
    end

    def format_inline_array(values, delimiter, prefix = nil, length_marker = false)
      header = format_header(values.length, key: prefix, delimiter: delimiter, length_marker: length_marker)
      joined_value = join_encoded_values(values, delimiter)
      # Only add space if there are values
      if values.empty?
        header
      else
        "#{header} #{joined_value}"
      end
    end

    # Array of objects (tabular format)
    def encode_array_of_objects_as_tabular(prefix, rows, header, writer, depth, options)
      header_str = format_header(rows.length, key: prefix, fields: header, delimiter: options[:delimiter], length_marker: options[:length_marker])
      writer.push(depth, header_str)

      write_tabular_rows(rows, header, writer, depth + 1, options)
    end

    def detect_tabular_header(rows)
      return nil if rows.empty?

      first_row = rows[0]
      first_keys = first_row.keys
      return nil if first_keys.empty?

      if tabular_array?(rows, first_keys)
        first_keys
      else
        nil
      end
    end

    def tabular_array?(rows, header)
      rows.all? do |row|
        keys = row.keys

        # All objects must have the same keys (but order can differ)
        return false if keys.length != header.length

        # Check that all header keys exist in the row and all values are primitives
        header.all? do |key|
          row.key?(key) && json_primitive?(row[key])
        end
      end
    end

    def write_tabular_rows(rows, header, writer, depth, options)
      rows.each do |row|
        values = header.map { |key| row[key] }
        joined_value = join_encoded_values(values, options[:delimiter])
        writer.push(depth, joined_value)
      end
    end

    # Array of objects (expanded format)
    def encode_mixed_array_as_list_items(prefix, items, writer, depth, options)
      header = format_header(items.length, key: prefix, delimiter: options[:delimiter], length_marker: options[:length_marker])
      writer.push(depth, header)

      items.each do |item|
        if json_primitive?(item)
          # Direct primitive as list item
          writer.push(depth + 1, "#{LIST_ITEM_PREFIX}#{encode_primitive(item, options[:delimiter])}")
        elsif json_array?(item)
          # Direct array as list item
          if array_of_primitives?(item)
            inline = format_inline_array(item, options[:delimiter], nil, options[:length_marker])
            writer.push(depth + 1, "#{LIST_ITEM_PREFIX}#{inline}")
          end
        elsif json_object?(item)
          # Object as list item
          encode_object_as_list_item(item, writer, depth + 1, options)
        end
      end
    end

    def encode_object_as_list_item(obj, writer, depth, options)
      keys = obj.keys
      if keys.empty?
        writer.push(depth, LIST_ITEM_MARKER)
        return
      end

      # First key-value on the same line as "- "
      first_key = keys[0]
      encoded_key = encode_key(first_key)
      first_value = obj[first_key]

      if json_primitive?(first_value)
        writer.push(depth, "#{LIST_ITEM_PREFIX}#{encoded_key}: #{encode_primitive(first_value, options[:delimiter])}")
      elsif json_array?(first_value)
        if array_of_primitives?(first_value)
          # Inline format for primitive arrays
          formatted = format_inline_array(first_value, options[:delimiter], first_key, options[:length_marker])
          writer.push(depth, "#{LIST_ITEM_PREFIX}#{formatted}")
        elsif array_of_objects?(first_value)
          # Check if array of objects can use tabular format
          header = detect_tabular_header(first_value)
          if header
            # Tabular format for uniform arrays of objects
            header_str = format_header(first_value.length, key: first_key, fields: header, delimiter: options[:delimiter], length_marker: options[:length_marker])
            writer.push(depth, "#{LIST_ITEM_PREFIX}#{header_str}")
            write_tabular_rows(first_value, header, writer, depth + 1, options)
          else
            # Fall back to list format for non-uniform arrays of objects
            writer.push(depth, "#{LIST_ITEM_PREFIX}#{encoded_key}[#{first_value.length}]:")
            first_value.each do |item|
              encode_object_as_list_item(item, writer, depth + 1, options)
            end
          end
        else
          # Complex arrays on separate lines (array of arrays, etc.)
          writer.push(depth, "#{LIST_ITEM_PREFIX}#{encoded_key}[#{first_value.length}]:")

          # Encode array contents at depth + 1
          first_value.each do |item|
            if json_primitive?(item)
              writer.push(depth + 1, "#{LIST_ITEM_PREFIX}#{encode_primitive(item, options[:delimiter])}")
            elsif json_array?(item) && array_of_primitives?(item)
              inline = format_inline_array(item, options[:delimiter], nil, options[:length_marker])
              writer.push(depth + 1, "#{LIST_ITEM_PREFIX}#{inline}")
            elsif json_object?(item)
              encode_object_as_list_item(item, writer, depth + 1, options)
            end
          end
        end
      elsif json_object?(first_value)
        nested_keys = first_value.keys
        if nested_keys.empty?
          writer.push(depth, "#{LIST_ITEM_PREFIX}#{encoded_key}:")
        else
          writer.push(depth, "#{LIST_ITEM_PREFIX}#{encoded_key}:")
          encode_object(first_value, writer, depth + 2, options)
        end
      end

      # Remaining keys on indented lines
      (1...keys.length).each do |i|
        key = keys[i]
        encode_key_value_pair(key, obj[key], writer, depth + 1, options)
      end
    end
  end
end
