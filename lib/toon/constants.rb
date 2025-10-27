# frozen_string_literal: true

module Toon
  # List markers
  LIST_ITEM_MARKER = '-'
  LIST_ITEM_PREFIX = '- '

  # Structural characters
  COMMA = ','
  COLON = ':'
  SPACE = ' '
  PIPE = '|'

  # Brackets and braces
  OPEN_BRACKET = '['
  CLOSE_BRACKET = ']'
  OPEN_BRACE = '{'
  CLOSE_BRACE = '}'

  # Literals
  NULL_LITERAL = 'null'
  TRUE_LITERAL = 'true'
  FALSE_LITERAL = 'false'

  # Escape characters
  BACKSLASH = '\\'
  DOUBLE_QUOTE = '"'
  NEWLINE = "\n"
  CARRIAGE_RETURN = "\r"
  TAB = "\t"

  # Delimiters
  DELIMITERS = {
    comma: COMMA,
    tab: TAB,
    pipe: PIPE
  }.freeze

  DEFAULT_DELIMITER = DELIMITERS[:comma]
end
