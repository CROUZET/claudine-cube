# frozen_string_literal: true

# Calibration / verification of the cube EDGES (CLAUDE.md §4).
#
# Each edge shared by 2 faces is lit ON BOTH ITS FACES, pixels 2→6 (the middle 5, we leave the corners out to avoid confusion where 3 faces meet), in a color specific to each edge.
# The two pixels with the same index on either side of an edge are physically the SAME point of the cube.
#
# READING, cube sitting on the table:
#   - On each edge, the two faces must show a SINGLE continuous band of the right color, aligned pixel to pixel across the seam.
#   - If, on an edge, the band of one face is offset / reversed / on the wrong row relative to the other face → the mapping of that edge is to be corrected.
#
# The 4 side↔side edges are safe (surveyed mapping).
# The front→top edge is calibrated.
# The 3 other top↔side edges (right/back/left) are to be checked here; if one is offset, adjust `top_local` in lib/cube_mapping.rb then rerun.
#
# Close the serial monitor of the Arduino IDE before launching ("port busy").
require "logger"
require_relative "../lib/panel"

Claudine.logger.level = Logger::DEBUG

RED = [90, 0, 0].freeze
GREEN = [0, 90, 0].freeze
BLUE = [0, 0, 90].freeze
YELLOW = [90, 90, 0].freeze
MAGENTA = [90, 0, 90].freeze
CYAN = [0, 90, 90].freeze
ORANGE = [90, 40, 0].freeze
WHITE = [90, 90, 90].freeze

E = (2..6).to_a # pixels 2 to 6 along the edge

# [name, color, pixels face A, pixels face B] — A[i] and B[i] = same point.
EDGES = [
  ["front→right", RED, E.map { |i| [:front, 7, i] }, E.map { |i| [:right, 0, i] }],
  ["right→back", GREEN, E.map { |i| [:right, 7, i] }, E.map { |i| [:back, 0, i] }],
  ["back→left", BLUE, E.map { |i| [:back, 7, i] }, E.map { |i| [:left, 0, i] }],
  ["left→front", YELLOW, E.map { |i| [:left, 7, i] }, E.map { |i| [:front, 0, i] }],
  ["front→top", MAGENTA, E.map { |i| [:front, i, 7] }, E.map { |i| [:top, i, 0] }],
  ["right→top", CYAN, E.map { |i| [:right, i, 7] }, E.map { |i| [:top, 7, i] }],
  ["back→top", ORANGE, E.map { |i| [:back, i, 7] }, E.map { |i| [:top, 7 - i, 7] }],
  ["left→top", WHITE, E.map { |i| [:left, i, 7] }, E.map { |i| [:top, 0, 7 - i] }],
].freeze

panel = Claudine::Panel.new
EDGES.each do |_name, col, a, b|
  (a + b).each { |face, x, y| panel.set(face:, x:, y:, r: col[0], g: col[1], b: col[2]) }
end
panel.show

puts "\nEdges (pixels 2→6 on both sides, one color per edge):"
NAMES = { RED => "RED", GREEN => "GREEN", BLUE => "BLUE", YELLOW => "YELLOW", MAGENTA => "MAGENTA", CYAN => "CYAN", ORANGE => "ORANGE", WHITE => "WHITE" }.freeze
EDGES.each { |name, col, _a, _b| puts format("  %-16s -> %s", name, NAMES[col]) }
puts <<~MSG

  To confirm on the cube:
    - each edge = ONE continuous band, aligned pixel to pixel across the seam;
    - in particular right/back/left → top (not yet calibrated).
  If a band offsets crossing to the TOP -> adjust top_local (cube_mapping.rb).
MSG

panel.close
