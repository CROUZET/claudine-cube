# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "tmpdir"
require "fileutils"
require_relative "../lib/config"
require_relative "../config/settings"

# Config: precedence, safe-boot ceiling, volatile boost, integrations, theme, and robust file I/O.
# No hardware.
class ConfigTest < Minitest::Test
  DEFAULT = Claudine::Settings::BRIGHTNESS
  CEILING = Claudine::Config::BOOST_CEILING

  def setup
    @env = ENV.to_hash
    ENV.delete("CLAUDINE_BRIGHTNESS")
    ENV.delete("CLAUDINE_ANIMATION_SET")
    @dir = Dir.mktmpdir
    @file = File.join(@dir, ".claudine")
  end

  def teardown
    ENV.replace(@env)
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def cfg = Claudine::Config.new(path: @file)
  def write(hash) = File.write(@file, JSON.generate(hash))

  # --- brightness precedence ------------------------------------------------
  def test_default_when_no_env_no_file
    assert_in_delta DEFAULT, cfg.brightness, 1e-9
  end

  def test_env_override_honored_as_is
    ENV["CLAUDINE_BRIGHTNESS"] = "0.5" # may exceed the ceiling (deliberate)

    assert_in_delta 0.5, cfg.brightness, 1e-9
  end

  def test_file_value_used_without_env
    write("brightness" => 0.12)

    assert_in_delta 0.12, cfg.brightness, 1e-9
  end

  def test_env_beats_file
    write("brightness" => 0.12)
    ENV["CLAUDINE_BRIGHTNESS"] = "0.3"

    assert_in_delta 0.3, cfg.brightness, 1e-9
  end

  def test_file_above_ceiling_clamped_at_load
    write("brightness" => 0.9)

    assert_in_delta CEILING, cfg.brightness, 1e-9
  end

  # --- safe-boot ceiling / persistence --------------------------------------
  def test_set_within_ceiling_persists
    c = cfg
    c.brightness = 0.1

    assert_in_delta 0.1, Claudine::Config.new(path: @file).brightness, 1e-9
    assert_in_delta 0.1, JSON.parse(File.read(@file))["brightness"], 1e-9
  end

  def test_boost_above_ceiling_is_volatile
    write("brightness" => 0.1)
    c = Claudine::Config.new(path: @file)
    c.brightness = 0.5

    assert_in_delta 0.5, c.brightness, 1e-9
    assert_predicate c, :boost?
    assert_in_delta 0.1, JSON.parse(File.read(@file))["brightness"], 1e-9 # not written
    assert_in_delta 0.1, Claudine::Config.new(path: @file).brightness, 1e-9 # not restored
  end

  # --- robustness -----------------------------------------------------------
  def test_invalid_json_falls_back_to_default
    File.write(@file, "this is not json{")

    assert_in_delta DEFAULT, cfg.brightness, 1e-9
  end

  def test_write_preserves_other_keys
    write("brightness" => 0.1, "theme" => "bunny")
    c = cfg
    c.brightness = 0.2

    assert_equal "bunny", JSON.parse(File.read(@file))["theme"]
  end

  # --- integrations ---------------------------------------------------------
  def test_integrations_default_on
    c = cfg

    assert c.integration_enabled?(:claude_code)
    assert c.integration_enabled?(:whatever) # unknown defaults on
    assert c.to_state[:integrations]["claude_code"]
  end

  def test_set_integration_persists
    c = cfg
    c.set_integration("claude_code", false)

    refute c.integration_enabled?(:claude_code)
    refute JSON.parse(File.read(@file))["integrations"]["claude_code"]
    refute Claudine::Config.new(path: @file).integration_enabled?(:claude_code)
  end

  def test_brightness_and_integrations_coexist
    c = cfg
    c.set_integration("claude_code", false)
    c.brightness = 0.1
    data = JSON.parse(File.read(@file))

    assert_in_delta 0.1, data["brightness"], 1e-9
    refute data["integrations"]["claude_code"]
  end

  def test_any_integration_enabled
    c = cfg

    assert_predicate c, :any_integration_enabled?
    c.set_integration("claude_code", false)

    refute_predicate c, :any_integration_enabled?
  end

  # --- theme ----------------------------------------------------------------
  def test_theme_default_from_file_and_env_precedence
    assert_equal "cube", cfg.theme
    write("theme" => "bunny")

    assert_equal "bunny", cfg.theme
    ENV["CLAUDINE_ANIMATION_SET"] = "cube"

    assert_equal "cube", cfg.theme # ENV beats file
  end

  def test_theme_persists
    write("theme" => "bunny")
    c = Claudine::Config.new(path: @file) # boots 'bunny' from file
    c.theme = "cube"

    assert_equal "cube", Claudine::Config.new(path: @file).theme
    assert_equal "cube", Claudine::Config.new(path: @file).to_state[:theme]
  end
end
