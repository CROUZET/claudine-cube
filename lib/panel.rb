# frozen_string_literal: true

require_relative "rubyserial_patch" # must be required before any use of rubyserial
require_relative "../config/settings"
require_relative "cube_mapping"
require_relative "logger"

module Claudine
  class Panel
    WIDTH = Settings::WIDTH # 8, per face
    HEIGHT = Settings::HEIGHT # 8, per face
    NUM_LEDS = Settings::NUM_LEDS

    # ~1500 baud-time after the last byte is enough for FastLED.show() to latch.
    # We take a margin: 150 ms.
    CLOSE_FLUSH_DELAY = 0.15

    attr_accessor :brightness

    def initialize(port: Settings::PORT, baud: Settings::BAUD, brightness: Settings::BRIGHTNESS)
      Claudine.logger.info "Panel: opening #{port} @ #{baud} baud"
      @serial = Serial.new(port, baud)
      @brightness = brightness
      Claudine.logger.debug "Panel: waiting for ESP32 boot (2s)"
      sleep 2
      Claudine.logger.info "Panel: ESP32 ready (brightness=#{@brightness})"
      @buffer = Array.new(NUM_LEDS) { [0, 0, 0] }
      clear
    end

    def clear
      fill(0, 0, 0)
    end

    def fill(r, g, b)
      @buffer.each do |px|
        px[0] = r
        px[1] = g
        px[2] = b
      end
    end

    # Sets one pixel on a given face using logical coordinates.
    #   face : symbol (:front/:right/:back/:left/:top) or 0..4
    #   x    : column 0..7 (0 = left)
    #   y    : row    0..7 (0 = bottom)
    # The physical wiring of each face is absorbed by CubeMapping.
    def set(face:, x:, y:, r:, g:, b:)
      return if x.negative? || x >= WIDTH || y.negative? || y >= HEIGHT

      @buffer[CubeMapping.index(face, x, y)] = [r, g, b]
    end

    # Fills a whole face with a single color.
    def fill_face(face, r, g, b)
      HEIGHT.times do |y|
        WIDTH.times do |x|
          @buffer[CubeMapping.index(face, x, y)] = [r, g, b]
        end
      end
    end

    # Writes directly into the buffer by LED index, bypassing the x/y mapping.
    # Useful for diagnosing the panel's physical wiring.
    def set_raw(index, r, g, b)
      return if index.negative? || index >= NUM_LEDS

      @buffer[index] = [r, g, b]
    end

    def show
      pixels = @buffer.flat_map { |r, g, b| [scale(r), scale(g), scale(b)] }
      frame = (adalight_header + pixels).pack("C*")
      @serial.write(frame)
      Claudine.logger.debug "Panel: frame sent (#{frame.bytesize} bytes, #{NUM_LEDS} pixels)"
    end

    def close
      Claudine.logger.debug "Panel: flush (#{CLOSE_FLUSH_DELAY}s) before close"
      sleep CLOSE_FLUSH_DELAY
      @serial.close
      Claudine.logger.info "Panel: serial closed"
    end

    private

    def scale(v)
      (v * @brightness).round.clamp(0, 255)
    end

    def adalight_header
      count = NUM_LEDS - 1
      hi = (count >> 8) & 0xFF
      lo = count & 0xFF
      [0x41, 0x64, 0x61, hi, lo, hi ^ lo ^ 0x55]
    end
  end
end
