module Claudine
  # The intention vocabulary (v1) — see docs/INTENTIONS.md.
  #
  # Decouples event sources from animations: animations are indexed by
  # *intention* (not by hook), a profile maps a source's events onto these
  # intentions, and the temporal `kind` lives here — not hardcoded in the
  # AnimationManager. Adding a source is writing a profile; the render path is
  # untouched.
  module Intentions
    VERSION = 'intentions.v1'.freeze

    # For each intention:
    #   kind     : :ambient  — background loop, plays as long as the state lasts
    #              :pulse    — one-shot overlay, plays once then reverts to bg
    #              :boundary — start/end that cuts the background (terminal)
    #              :dormant  — idle
    #   fallback : intention to fall back on when a set does not define this one
    #              (nil = none; the mandatory-core intentions have no fallback).
    VOCAB = {
      welcome: { kind: :boundary, fallback: :think },
      think:   { kind: :ambient,  fallback: nil },
      start:   { kind: :pulse,    fallback: :think },
      finish:  { kind: :pulse,    fallback: :think },
      handle:  { kind: :pulse,    fallback: :start },
      handled: { kind: :pulse,    fallback: :finish },
      fork:    { kind: :pulse,    fallback: :start },
      join:    { kind: :pulse,    fallback: :finish },
      wait:    { kind: :pulse,    fallback: :think },
      retry:   { kind: :pulse,    fallback: :think },
      save:    { kind: :pulse,    fallback: :start },
      saved:   { kind: :pulse,    fallback: :finish },
      stop:    { kind: :boundary, fallback: nil },
      fail:    { kind: :boundary, fallback: :stop },
      bye:     { kind: :boundary, fallback: :stop },
      sleep:   { kind: :dormant,  fallback: nil },
    }.freeze

    # A pack must define at least these to be valid and playable.
    CORE = %i[think stop sleep].freeze

    module_function

    def known?(intention)
      VOCAB.key?(intention)
    end

    def kind(intention)
      VOCAB.fetch(intention)[:kind]
    end

    def fallback(intention)
      VOCAB.fetch(intention, {})[:fallback]
    end

    # Walks the fallback chain until it reaches an intention present in
    # `available` (any object responding to #include? — e.g. the registry keys).
    # Returns that intention, or nil if the chain runs dry. Cycle-safe.
    def resolve(intention, available)
      seen = {}
      cur  = intention
      while cur && !seen[cur]
        return cur if available.include?(cur)
        seen[cur] = true
        cur = VOCAB.fetch(cur, {})[:fallback]
      end
      nil
    end
  end
end
