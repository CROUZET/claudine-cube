# frozen_string_literal: true

require_relative "welcome"

module Claudine
  module Animations
    module Cube
      # End of session: same diagonal wave as the opening (rises then
      # ebbs back until extinction), but in cool colors. Opening and
      # closing share the gesture; the palette temperature opposes them
      # (warm at wake-up, cool at the end).
      class Bye < Welcome
        # Cool, wide range for more variety: yellow-green (0.25) -> green ->
        # cyan -> blue -> indigo -> violet (0.85).
        HUE0 = 0.25
        HUE1 = 0.85
      end
    end
  end
end
