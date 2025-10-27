# frozen_string_literal: true

require 'set'
require 'date'

module Toon
  module Normalizer
    module_function

    # Normalization (unknown → JSON-compatible value)
    def normalize_value(value)
      # null
      return nil if value.nil?

      # Primitives
      return value if value.is_a?(String) || value.is_a?(TrueClass) || value.is_a?(FalseClass)

      # Numbers: handle special cases
      if value.is_a?(Numeric)
        # Float special cases
        if value.is_a?(Float)
          # -0.0 becomes 0
          return 0 if value.zero? && (1.0 / value).negative?
          # NaN and Infinity become nil
          return nil unless value.finite?
        end
        return value
      end

      # Symbol → string
      return value.to_s if value.is_a?(Symbol)

      # Time → ISO8601 string
      if value.is_a?(Time)
        return value.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      # DateTime → ISO8601 string
      if value.respond_to?(:iso8601) && !value.is_a?(Date)
        return value.iso8601
      end

      # Date → ISO8601 string
      if value.is_a?(Date)
        return value.to_time.utc.iso8601
      end

      # Array
      if value.is_a?(Array)
        return value.map { |v| normalize_value(v) }
      end

      # Set → array
      if value.is_a?(Set)
        return value.to_a.map { |v| normalize_value(v) }
      end

      # Hash/object
      if value.is_a?(Hash)
        result = {}
        value.each do |k, v|
          result[k.to_s] = normalize_value(v)
        end
        return result
      end

      # Fallback: anything else becomes nil (functions, etc.)
      nil
    end

    # Type guards
    def json_primitive?(value)
      value.nil? ||
        value.is_a?(String) ||
        value.is_a?(Numeric) ||
        value.is_a?(TrueClass) ||
        value.is_a?(FalseClass)
    end

    def json_array?(value)
      value.is_a?(Array)
    end

    def json_object?(value)
      value.is_a?(Hash)
    end

    # Array type detection
    def array_of_primitives?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_primitive?(item) }
    end

    def array_of_arrays?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_array?(item) }
    end

    def array_of_objects?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_object?(item) }
    end
  end
end
