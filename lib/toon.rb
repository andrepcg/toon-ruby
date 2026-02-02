# frozen_string_literal: true

require_relative 'toon/version'
require_relative 'toon/constants'
require_relative 'toon/writer'
require_relative 'toon/normalizer'
require_relative 'toon/primitives'
require_relative 'toon/encoders'

module Toon
  module_function

  # Encode any value to TOON format
  #
  # @param input [Object] Any value to encode
  # @param indent [Integer] Number of spaces per indentation level (default: 2)
  # @param delimiter [String] Delimiter for array values and tabular rows (default: ',')
  # @param length_marker [String, false] Optional marker to prefix array lengths (default: false)
  # @return [String] TOON-formatted string
  # @return [nil] if writing to output
  def encode(input, indent: 2, delimiter: DEFAULT_DELIMITER, length_marker: false, output: nil)
    normalized_value = Normalizer.normalize_value(input)
    options = resolve_options(indent: indent, delimiter: delimiter, length_marker: length_marker, output:)
    Encoders.encode_value(normalized_value, options)
  end

  def resolve_options(indent:, delimiter:, length_marker:, output:)
    {
      indent: indent,
      delimiter: delimiter,
      length_marker: length_marker,
      output: output
    }
  end
end
