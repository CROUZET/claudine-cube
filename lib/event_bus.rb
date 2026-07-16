require_relative 'logger'

module Claudine
  # Thread-safe event queue: several producers (connectors) push,
  # one consumer (Runner) drains between frames.
  class EventBus
    def initialize
      @queue = Queue.new
    end

    # Safe to call from any thread.
    def push(event)
      Claudine.logger.debug "EventBus: push #{event.type} #{event.payload.inspect}"
      @queue << event
    end

    # Non-blocking: returns all events accumulated since the last call,
    # in arrival order. Returns [] if the queue is empty.
    def drain
      events = []
      loop { events << @queue.pop(true) }
    rescue ThreadError
      events
    end

    def size
      @queue.size
    end
  end
end
