# frozen_string_literal: true

# Display limit test — all 320 LEDs lit, ramping up brightness.
#
# Goal: find the real limit of the cube (5 V / 10 A power supply + thermal + integrity of the serial stream on a "full" frame) by pushing ALL the LEDs to max.
# This is deliberately the worst case: full white on all 320 LEDs.
#
# ⚠️ SAFETY — read before launching:
#   - Full white (255,255,255) at brightness 1.0 on 320 LEDs draws ~19 A in theory (320 × 60 mA).
#     The power supply is only 10 A: it will limit (voltage drop → LEDs shifting, ESP brownout → reset).
#     This is precisely what we want to observe.
#   - KEEP THE DC JACK PLUGGED IN.
#     USB alone does not hold full white.
#   - It HEATS UP.
#     The test ramps up in STEPS and waits for a keypress between each so it can be stopped (Ctrl-C) as soon as the display goes off track or heats up.
#   - Do not leave at max unattended.
#
# The test bypasses the Panel's scaling (@brightness) and pushes the raw bytes to the firmware: the displayed step IS the value sent to the LEDs.
#
# MEASURED RESULTS (2026-07, cf. docs/HARDWARE.md "Hardware lessons"):
#   - DC jack plugged in: full white 100% on all 320 LEDs → nothing to report, no artifact (no hue shift, no flicker, no ESP brownout).
#     The ~19 A theoretical is very pessimistic; the 10 A power supply handles it cleanly.
#   - USB alone (no jack): OK at ~8%, but the ESP browns out (LEDs blinking) BETWEEN 20% and 25% of full white (USB source caps at ~4 A theo. worst-case).
#   → The practical limit is thermal (prolonged use), not the display.
#
# Close the serial monitor of the Arduino IDE before launching ("port busy").
#
# Options (env):
#   COLOR=white|red|green|blue    fill color (default white)
#   STEPS=0.08,0.25,0.5,0.75,1.0  brightness steps (default below)
#   AUTO=1                        chains the steps without waiting (3 s each)
require "logger"
require_relative "../lib/panel"

Claudine.logger.level = Logger::INFO

COLORS = {
  "white" => [255, 255, 255],
  "red" => [255, 0, 0],
  "green" => [0, 255, 0],
  "blue" => [0, 0, 255],
}.freeze
color_name = (ENV["COLOR"] || "white").downcase
base = COLORS[color_name] or abort "unknown COLOR: #{color_name} (choices: #{COLORS.keys.join(", ")})"

steps = (ENV["STEPS"] || "0.08,0.25,0.5,0.75,1.0").split(",").map(&:to_f)
auto = ENV["AUTO"] == "1"

# Approx. current per LED at full white ≈ 60 mA; we weight by the fraction
# of channels lit and by the brightness of the step.
channels_on = base.count(&:positive?) / 3.0
def est_current(brightness, channels_on)
  Claudine::Panel::NUM_LEDS * 0.060 * channels_on * brightness
end

panel = Claudine::Panel.new
panel.brightness = 1.0 # we manage the brightness ourselves, step by step

puts <<~MSG

  === DISPLAY LIMIT TEST ===
  Color: #{color_name} #{base.inspect}   |   320 LEDs lit
  Steps: #{steps.map { |s| (s * 100).round }.join("%, ")}%
  Power supply: 5 V / 10 A — beyond ~10 A the power supply limits (expected voltage drop).
  Ctrl-C to cut at any time.

MSG

begin
  steps.each_with_index do |b, i|
    val = base.map { |c| (c * b).round.clamp(0, 255) }
    panel.fill(*val)
    panel.show

    amps = est_current(b, channels_on)
    warn_flag = amps > 10 ? "  ⚠️ >10 A: beyond power supply capacity" : ""
    puts format("Step %d/%d — brightness %3d%% → bytes %-15s ~%.1f A%s",
                i + 1, steps.size, (b * 100).round, val.inspect, amps, warn_flag)

    if auto
      sleep 3
    else
      print "  [Enter] next step, [Ctrl-C] stop… "
      $stdin.gets
    end
  end

  puts "\nMax reached. Observe: uniform white? hue shift? flicker?"
  puts "ESP reset (brownout)? end-of-chain LEDs dropping out?"
  if auto
    sleep 3
  else
    print "Leave it on, [Enter] to turn off… "
    $stdin.gets
  end
rescue Interrupt
  puts "\nInterrupted."
ensure
  panel.clear
  panel.show
  panel.close
end
