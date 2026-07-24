# frozen_string_literal: true

require "minitest/autorun"
require "logger"
require "socket"

# Automated tests run without hardware. Keep logs quiet unless asked.
ENV["CLAUDINE_LOG_LEVEL"] ||= "ERROR"
require_relative "../lib/logger"
Claudine.logger.level = Logger::ERROR

# Stub panels shared across tests (the real Panel opens a serial port).
module TestPanels
  # Accepts every Panel call, records nothing.
  class Stub
    def clear; end
    def fill(*); end
    def fill_face(*); end
    def set(**); end
    def set_raw(*); end
  end

  # Records whether #clear was called (used to check one-shot blanking).
  class ClearSpy < Stub
    def initialize = @cleared = false
    def clear = @cleared = true
    def cleared? = @cleared
  end

  # Validates coordinates/colors like the real Panel + CubeMapping, so the animation smoke test catches out-of-bounds writes.
  class Fake
    FACES = %i[front right back left top].freeze

    attr_reader :writes

    def initialize = @writes = 0
    def clear; end
    def fill(_r, _g, _b); end

    def fill_face(face, _r, _g, _b)
      raise "invalid face: #{face.inspect}" unless FACES.include?(face)
    end

    def set(face:, x:, y:, r:, g:, b:)
      raise "invalid face: #{face.inspect}" unless FACES.include?(face)
      raise "x out of bounds: #{x.inspect}" unless x.is_a?(Integer) && (0..7).cover?(x)
      raise "y out of bounds: #{y.inspect}" unless y.is_a?(Integer) && (0..7).cover?(y)

      [r, g, b].each { |c| raise "invalid color: #{c.inspect}" unless c.is_a?(Integer) && (0..255).cover?(c) }
      @writes += 1
    end
  end
end

# A free localhost TCP port, so server-based tests never collide.
def free_port
  s = TCPServer.new("127.0.0.1", 0)
  port = s.addr[1]
  s.close
  port
end
