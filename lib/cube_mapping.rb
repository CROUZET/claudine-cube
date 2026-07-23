# frozen_string_literal: true

# ============================================================
#  cube_mapping.rb  —  logical mapping of the 5 x 8x8 LED cube
# ============================================================
#
#  Physical chain surveyed on the assembly:
#
#  Order of faces in the chain:
#     0 = front, 1 = right, 2 = back, 3 = left, 4 = top
#  (64 LEDs per face: face F occupies indices 64*F .. 64*F+63)
#
#  Path WITHIN each side face (faces 0..3), identical:
#     origin BOTTOM-LEFT corner, climb a whole column
#     (row 0 -> 7), then next column to the right.
#       index_local = col * 8 + row
#     with row = 0 at the bottom, col = 0 on the left.
#
#  Path of the TOP face (face 4):
#     origin TOP-LEFT corner, run through a whole row
#     to the right (col 0 -> 7), then the row below.
#       index_local = (7 - row) * 8 + col
#     with row = 0 at the bottom, col = 0 on the left (same logical frame).
#
#  LOGICAL COORDINATE CONVENTION (identical for all faces):
#     - x = column, 0 = left  .. 7 = right
#     - y = row,    0 = bottom .. 7 = top
#   This way an animation can reason in (face, x, y) without
#   worrying about the physical wiring direction: it is all absorbed here.
# ============================================================

module CubeMapping
  WIDTH = 8
  HEIGHT = 8
  PER_FACE = WIDTH * HEIGHT # 64
  FACES = 5
  NUM_LEDS = PER_FACE * FACES # 320

  # Face names -> number in the chain
  FACE = {
    front: 0, # front
    right: 1, # right
    back: 2, # back
    left: 3, # left
    top: 4, # top
  }.freeze

  # Local index (0..63) in a side face (faces 0..3).
  # Column by column, each column from bottom to top.
  #   x = column (0 left), y = row (0 bottom)
  def self.side_local(x, y)
    (x * HEIGHT) + y
  end

  # Local index (0..63) in the top face (face 4).
  # Row by row from top to bottom, each row from left to right.
  #   x = column (0 left), y = row (0 bottom)
  # The chain starts at the TOP (y = 7), hence (7 - y).
  def self.top_local(x, y)
    ((HEIGHT - 1 - y) * WIDTH) + x
  end

  # Entry point: (face, x, y) -> global index 0..319
  #   face : symbol (:front, :right, :back, :left, :top) or integer 0..4
  #   x    : column 0..7 (0 = left)
  #   y    : row    0..7 (0 = bottom)
  def self.index(face, x, y)
    f = face.is_a?(Symbol) ? FACE.fetch(face) : face
    raise ArgumentError, "face #{face} invalid" unless (0..4).cover?(f)
    raise ArgumentError, "x=#{x} out of bounds" unless (0...WIDTH).cover?(x)
    raise ArgumentError, "y=#{y} out of bounds" unless (0...HEIGHT).cover?(y)

    local = f == FACE[:top] ? top_local(x, y) : side_local(x, y)
    (f * PER_FACE) + local
  end
end

# ------------------------------------------------------------
#  Quick self-test: ruby cube_mapping.rb
#  Checks consistency with the physical survey.
# ------------------------------------------------------------
if __FILE__ == $PROGRAM_NAME
  m = CubeMapping

  checks = [
    # front face: bottom-left = 0, climbs the 1st column, then next column
    [:front, 0, 0, 0],
    [:front, 0, 1, 1],
    [:front, 0, 7, 7],
    [:front, 1, 0, 8],
    [:front, 7, 7, 63],
    # right face: offset by 64
    [:right, 0, 0, 64],
    [:right, 7, 7, 127],
    # back face
    [:back, 0, 0, 128],
    # left face
    [:left, 0, 0, 192],
    # top face: top-left = first index of the face (256)
    [:top, 0, 7, 256], # top-left corner
    [:top, 7, 7, 263], # end of the 1st row (top-right)
    [:top, 0, 6, 264], # row below, on the left
    [:top, 7, 0, 319], # bottom-right corner = last LED
  ]

  ok = true
  checks.each do |face, x, y, expected|
    got = m.index(face, x, y)
    status = got == expected ? "ok " : "XX "
    ok &&= (got == expected)
    puts "#{status} (#{face}, x=#{x}, y=#{y}) -> #{got}  (expected #{expected})"
  end

  puts ok ? "\nALL TESTS PASS ✅" : "\nFAILURE: review the mapping ❌"
end
