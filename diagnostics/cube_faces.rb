# frozen_string_literal: true

# Cube geometry validation (CLAUDE.md §5.3).
#
# Lights each face with a distinct color to confirm:
#   - the order of the faces in the chain (front→right→back→left→top),
#   - the integrity of the per-face mapping.
#
# Expected, cube sitting on the table, walking around it:
#   FRONT   (front) → RED
#   RIGHT   (right) → GREEN
#   BACK    (back)  → BLUE
#   LEFT    (left)  → YELLOW
#   TOP     (top)   → WHITE
#
# Close the serial monitor of the Arduino IDE before launching ("port busy").
require "logger"
require_relative "../lib/panel"

Claudine.logger.level = Logger::DEBUG

FACES = [
  [:front, [80, 0, 0], "FRONT", "RED"],
  [:right, [0, 80, 0], "RIGHT", "GREEN"],
  [:back, [0, 0, 80], "BACK", "BLUE"],
  [:left, [80, 80, 0], "LEFT", "YELLOW"],
  [:top, [80, 80, 80], "TOP", "WHITE"],
].freeze

panel = Claudine::Panel.new
FACES.each { |face, (r, g, b), _, _| panel.fill_face(face, r, g, b) }
panel.show

puts "\nOne color per face — check around the cube:"
FACES.each { |_, _, nom, couleur| puts format("  %-8s -> %s", nom, couleur) }
puts <<~MSG

  To confirm:
    - each face is indeed ONE single color, uniform (per-face mapping OK);
    - the order matches (otherwise review the order of the faces in the chain);
    - the TOP is uniform white (the rotation is calibrated with cube_edge.rb).
MSG

panel.close
