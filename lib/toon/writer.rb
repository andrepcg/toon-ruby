# frozen_string_literal: true

module Toon
  class LineWriter
    def initialize(indent_size)
      @lines = []
      @indentation_string = ' ' * indent_size
    end

    def push(depth, content)
      indent = @indentation_string * depth
      @lines << indent + content
    end

    def to_s
      @lines.join("\n")
    end
  end
  private_constant :LineWriter
end
