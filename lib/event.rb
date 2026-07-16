module Claudine
  # Immutable event flowing on the bus.
  #
  # `type`    : Symbol identifying the event kind (e.g. :change_animation).
  # `payload` : Hash of type-specific data (may be empty).
  #
  # Usage: Claudine::Event.new(type: :change_animation, payload: { name: :rainbow })
  Event = Data.define(:type, :payload)
end
