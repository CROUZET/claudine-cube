# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # End of turn (success): the cube first appears speckled with SHADES shades of yellow (from light to dark, randomly distributed), then turns off shade by shade -- all pixels of the same shade disappear together, at a regular interval (STEP), from the lightest to the darkest, until fully off.
      # Signature: yellow dissolve in steps, from light toward dark.
      class Stop < CubeBase
        SHADES = 8 # number of shades (n), from light to dark
        STEP = 0.3 # interval between two extinctions (s)
        LIGHT = [255, 225, 70].freeze # light yellow (first shade, turned off first)
        DARK = [90, 55, 0].freeze # dark yellow (last shade, turned off last)

        MIN_DURATION = SHADES * STEP # plays until fully off

        def initialize(_payload = {})
          # Palette light -> dark, and fixed assignment of a shade per pixel (once only: otherwise the speckle would flicker on every frame).
          @palette = (0...SHADES).map { |i| mix(LIGHT, DARK, i.to_f / (SHADES - 1)) }
          @tint = {}
          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times { |y| @tint[[face, x, y]] = rand(SHADES) }
            end
          end
        end

        def render(t, panel)
          panel.clear
          gone = (t / STEP).floor # shades already off (the lightest first)
          @tint.each do |(face, x, y), i|
            next if i < gone # this shade has disappeared

            rgb = @palette[i]
            px(panel, face, x, y, rgb)
          end
        end

        private

        # Linear interpolation between two colors (f: 0 -> a, 1 -> b).
        def mix(a, b, f)
          a.zip(b).map { |ca, cb| (ca + ((cb - ca) * f)).round.clamp(0, 255) }
        end
      end
    end
  end
end
