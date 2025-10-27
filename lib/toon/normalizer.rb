# frozen_string_literal: true

require 'set'
require 'date'

module Toon
  module Normalizer
    module_function

    # Normalization (unknown → JSON-compatible value)
    def normalize_value(value)
      case value
      when nil
        nil
      when String, TrueClass, FalseClass
        value
      when Numeric
        # Float special cases
        if value.is_a?(Float)
          # -0.0 becomes 0
          return 0 if value.zero? && (1.0 / value).negative?
          # NaN and Infinity become nil
          return nil unless value.finite?
        end
        value
      when Symbol
        value.to_s
      when Time
        value.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      when ->(v) { v.respond_to?(:iso8601) && !v.is_a?(Date) }
        value.iso8601
      when Date
        value.to_time.utc.iso8601
      when Array
        value.map { |v| normalize_value(v) }
      when Set
        value.to_a.map { |v| normalize_value(v) }
      when Hash
        value.each_with_object({}) { |(k, v), h| h[k.to_s] = normalize_value(v) }
      else
        # Fallback: anything else becomes nil (functions, etc.)
        nil
      end
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
