module Claudine
  module Settings
    PORT   = '/dev/cu.usbmodem11201'   # Seeed XIAO ESP32-S3
    # 921600 baud → ~92 kB/s. MUST match the BAUD compiled into
    # sketch_firmware/sketch_firmware.ino.
    BAUD   = 921600

    # Cube geometry: 5 faces of 8×8 = 320 LEDs. WIDTH/HEIGHT are per-face.
    # The physical wiring of each face is handled by CubeMapping.
    WIDTH    = 8
    HEIGHT   = 8
    FACES    = 5
    NUM_LEDS = WIDTH * HEIGHT * FACES   # 320

    # Render loop cadence.
    FPS = 30

    # Minimum time (seconds) a hook animation must remain on screen before
    # a newer event is allowed to take over. Events arriving within this
    # window are buffered (latest-wins, 1 slot) by AnimationManager.
    # Overridable per animation via a MIN_DURATION constant on the class.
    MIN_ANIMATION_DURATION = 0.6

    # Seconds of inactivity (no incoming event) before AnimationManager
    # switches to the set's system_idle animation (or blanks the panel if
    # the set has none). Set to nil to disable — LEDs will then hold the
    # last event forever.
    IDLE_TIMEOUT = 90.0

    # TCP port for the Claude Code connector (local HTTP server).
    CLAUDE_CODE_PORT = 9292

    # 0.0–1.0 factor applied on the Ruby side (the firmware runs at 255).
    # ~0.08 (≈20/255) is the working brightness: ~1.5 A total on the cube,
    # natural convection is enough. Raise cautiously (thermal / power).
    BRIGHTNESS = 0.08
  end
end
