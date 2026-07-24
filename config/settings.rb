# frozen_string_literal: true

module Claudine
  module Settings
    PORT = "/dev/cu.usbmodem11201" # Seeed XIAO ESP32-S3

    # 921600 baud → ~92 kB/s.
    # MUST match the BAUD compiled into sketch_firmware/sketch_firmware.ino.
    BAUD = 921_600

    # Cube geometry: 5 faces of 8×8 = 320 LEDs.
    # WIDTH/HEIGHT are per-face.
    # The physical wiring of each face is handled by CubeMapping.
    WIDTH = 8
    HEIGHT = 8
    FACES = 5
    NUM_LEDS = WIDTH * HEIGHT * FACES

    # Render loop cadence.
    FPS = 30

    # Default animation set (a directory under lib/animations/).
    # Overridable via CLAUDINE_ANIMATION_SET or the admin page (persisted to ~/.claudine).
    DEFAULT_ANIMATION_SET = "cube"

    # Minimum time (seconds) a hook animation must remain on screen before a newer event is allowed to take over.
    # Events arriving within this window are buffered (latest-wins, 1 slot) by AnimationManager.
    # Overridable per animation via a MIN_DURATION constant on the class.
    MIN_ANIMATION_DURATION = 0.6

    # Seconds of inactivity (no incoming event) before AnimationManager switches to the set's system_idle animation (or blanks the panel if the set has none).
    # Set to nil to disable — LEDs will then hold the last event forever.
    IDLE_TIMEOUT = 90.0

    # Local-only bind address shared by the HTTP connectors (hooks + admin).
    LOCAL_HOST = "127.0.0.1"

    # TCP port for the Claude Code connector (local HTTP server, receives hooks).
    CLAUDE_CODE_PORT = 9292

    # TCP port for the admin control-plane web server (WEBrick).
    ADMIN_PORT = 9293

    # 0.0–1.0 factor applied on the Ruby side (the firmware runs at 255).
    # ~0.08 (≈20/255) is the working brightness: ~1.5A total on the cube, natural convection is enough.
    # Raise cautiously (thermal / power).
    # Overridable for testing: CLAUDINE_BRIGHTNESS=0.12 ruby ...
    BRIGHTNESS = (ENV["CLAUDINE_BRIGHTNESS"] || "0.08").to_f

    # Above this factor, a brightness setting is a volatile *session boost*: applied live but never persisted, so a fresh (possibly USB-only) boot can never brown out on a stale high value.
    # See docs/HARDWARE.md.
    BRIGHTNESS_BOOST_CEILING = 0.25
  end
end
