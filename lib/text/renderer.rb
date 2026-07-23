# frozen_string_literal: true

require_relative "font_3x5"

module Claudine
  module Text
    # Paints a string on a Panel using the 3×5 font.
    # Each character takes 3 columns; 1-column spacing between characters.
    # 4 characters → 15 columns, leaving 1 free column out of 16.
    module Renderer
      CHAR_SPACING = 1
      CHAR_STEP = Font3x5::WIDTH + CHAR_SPACING # 4 px horizontal step

      # Writes `text` (upcased) on `panel` starting at corner (x, y).
      # Does not clear the panel; only paints the "on" pixels.
      def self.draw(panel, text, x, y, r, g, b)
        text.to_s.upcase.each_char.with_index do |char, i|
          draw_char(panel, char, x + (i * CHAR_STEP), y, r, g, b)
        end
      end

      def self.draw_char(panel, char, x, y, r, g, b)
        rows = Font3x5.glyph(char)
        rows.each_with_index do |row_bits, row|
          Font3x5::WIDTH.times do |col|
            bit = (row_bits >> (Font3x5::WIDTH - 1 - col)) & 1
            panel.set(x + col, y + row, r, g, b) if bit == 1
          end
        end
      end
    end
  end
end
