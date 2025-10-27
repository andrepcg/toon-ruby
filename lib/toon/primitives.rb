# frozen_string_literal: true

require_relative 'constants'

module Toon
  module Primitives
    module_function

    # Primitive encoding
    def encode_primitive(value, delimiter = COMMA)
      return NULL_LITERAL if value.nil?
      return value.to_s if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      return value.to_s if value.is_a?(Numeric)

      encode_string_literal(value, delimiter)
    end

    def encode_string_literal(value, delimiter = COMMA)
      if safe_unquoted?(value, delimiter)
        value
      else
        "#{DOUBLE_QUOTE}#{escape_string(value)}#{DOUBLE_QUOTE}"
      end
    end

    def escape_string(value)
      value
        .gsub(BACKSLASH, "#{BACKSLASH}#{BACKSLASH}")
        .gsub(DOUBLE_QUOTE, "#{BACKSLASH}#{DOUBLE_QUOTE}")
        .gsub("\n", "#{BACKSLASH}n")
        .gsub("\r", "#{BACKSLASH}r")
        .gsub("\t", "#{BACKSLASH}t")
    end

    def safe_unquoted?(value, delimiter = COMMA)
      return false if value.empty?
      return false if padded_with_whitespace?(value)
      return false if value == TRUE_LITERAL || value == FALSE_LITERAL || value == NULL_LITERAL
      return false if numeric_like?(value)
      return false if value.include?(COLON)
      return false if value.include?(DOUBLE_QUOTE) || value.include?(BACKSLASH)
      return false if value.match?(/[\[\]{}]/)
      return false if value.match?(/[\n\r\t]/)
      return false if value.include?(delimiter)
      return false if value.start_with?(LIST_ITEM_MARKER)

      true
    end

    def numeric_like?(value)
      # Match numbers like: 42, -3.14, 1e-6, 05, etc.
      value.match?(/^-?\d+(?:\.\d+)?(?:e[+-]?\d+)?$/i) || value.match?(/^0\d+$/)
    end

    def padded_with_whitespace?(value)
      value != value.strip
    end

    # Key encoding
    def encode_key(key)
      if valid_unquoted_key?(key)
        key
      else
        "#{DOUBLE_QUOTE}#{escape_string(key)}#{DOUBLE_QUOTE}"
      end
    end

    def valid_unquoted_key?(key)
      # Keys must not contain control characters or special characters
      return false if key.match?(/[\n\r\t]/)
      return false if key.include?(COLON)
      return false if key.include?(DOUBLE_QUOTE) || key.include?(BACKSLASH)
      return false if key.match?(/[\[\]{}]/)
      return false if key.include?(COMMA)
      return false if key.start_with?(LIST_ITEM_MARKER)
      return false if key.empty?
      return false if key.match?(/^\d+$/)  # Numeric keys
      return false if key != key.strip  # Leading/trailing spaces

      key.match?(/^[A-Z_][\w.]*$/i)
    end

    # Value joining
    def join_encoded_values(values, delimiter = COMMA)
      values.map { |v| encode_primitive(v, delimiter) }.join(delimiter)
    end

    # Header formatters
    def format_header(length, key: nil, fields: nil, delimiter: COMMA, length_marker: false)
      header = ''

      header += encode_key(key) if key

      # Only include delimiter if it's not the default (comma)
      delimiter_suffix = delimiter != DEFAULT_DELIMITER ? delimiter : ''
      length_prefix = length_marker ? length_marker : ''
      header += "[#{length_prefix}#{length}#{delimiter_suffix}]"

      if fields
        quoted_fields = fields.map { |f| encode_key(f) }
        header += "{#{quoted_fields.join(delimiter)}}"
      end

      header += COLON

      header
    end
  end
end
