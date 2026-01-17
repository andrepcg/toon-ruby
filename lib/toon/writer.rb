# frozen_string_literal: true

module Toon
  # LineWriter is a utility class for building formatted output lines with
  # consistent indentation.
  #
  # It manages the construction of output strings by handling indentation and
  # line termination.
  #
  # @api private
  class LineWriter
    # Initializes a new LineWriter instance with the specified indentation size
    # and optional output target.
    #
    # @param indent_size [ Integer ] the number of spaces to use for each
    #   indentation level @param output [ StringIO, nil ] the output target to
    # write to, or nil to use a new StringIO instance
    def initialize(indent_size, output = nil)
      @output = output || StringIO.new
      @indentation_string = ' ' * indent_size
      @started = false
    end

    # Pushes a content line with specified indentation to the output.
    #
    # @param depth [ Integer ] the indentation depth level
    # @param content [ String ] the content to push
    # @return [ LineWriter ] returns self to allow method chaining
    def push(depth, content)
      indent = @indentation_string * depth
      @output << ?\n if @started
      @output << indent + content
      @started = true
      self
    end

    # Returns the string representation of the written content with trailing
    # newlines removed.
    #
    # @return [ String ] the final output string with trailing newline stripped
    def to_s
      @output.string
    end
  end
  private_constant :LineWriter
end
