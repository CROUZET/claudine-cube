# frozen_string_literal: true

module Claudine
  # Thread-safe holder for a runtime status snapshot, for the admin status panel.
  # The Runner publishes a fresh frozen hash every frame (render thread); the AdminServer reads the current reference from its own thread.
  # Swapping and reading a single reference is atomic under the GIL, so no lock is needed — a reader always sees a whole, self-consistent snapshot (never a torn one).
  class Status
    def initialize
      @snapshot = {}.freeze
    end

    def publish(hash)
      @snapshot = hash.freeze
    end

    def current
      @snapshot
    end
  end
end
