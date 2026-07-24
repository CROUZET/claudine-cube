# frozen_string_literal: true

require_relative "test_helper"
require "net/http"
require "json"
require "tmpdir"
require "fileutils"
require_relative "../lib/event"
require_relative "../lib/event_bus"
require_relative "../lib/config"
require_relative "../lib/status"
require_relative "../lib/connectors/admin_server"

# AdminServer: the whole control-plane HTTP API, isolated (no Panel → no serial).
class AdminServerTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @cfg = Claudine::Config.new(path: File.join(@dir, ".claudine"))
    @status = Claudine::Status.new
    @status.publish(state: "working", animation: "Think", uptime_s: 5)
    @bus = Claudine::EventBus.new
    @port = free_port
    @srv = Claudine::Connectors::AdminServer.new(config: @cfg, status: @status, bus: @bus, port: @port)
    @srv.start
    30.times do
      get("/api/state")
      break
    rescue Errno::ECONNREFUSED
      sleep 0.05
    end
  end

  def teardown
    @srv&.stop
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def get(path) = Net::HTTP.new("127.0.0.1", @port).get(path)
  def post(path, body) = Net::HTTP.new("127.0.0.1", @port).post(path, body, "Content-Type" => "application/json")

  def test_state
    r = get("/api/state")

    assert_equal "200", r.code
    assert_includes r["content-type"], "application/json"
    s = JSON.parse(r.body)

    assert s.key?("brightness")
    assert_in_delta(0.25, s["boost_ceiling"])
    assert_kind_of Hash, s["integrations"]
    assert s["integrations"].key?("claude_code")
    assert_includes s["themes"], "cube"
    assert_includes s["intentions"], "fork"
  end

  def test_status
    s = JSON.parse(get("/api/status").body)

    assert_equal "working", s["state"]
    assert_equal "Think", s["animation"]
  end

  def test_brightness
    assert_equal "204", post("/api/brightness", JSON.generate("value" => 0.1)).code
    assert_in_delta 0.1, @cfg.brightness, 1e-9
    assert_in_delta 0.1, JSON.parse(get("/api/state").body)["brightness"], 1e-9
    assert_equal "400", post("/api/brightness", JSON.generate("nope" => 1)).code
    assert_equal "400", post("/api/brightness", "not json").code
  end

  def test_integration
    assert_equal "204", post("/api/integration", JSON.generate("name" => "claude_code", "enabled" => false)).code
    refute @cfg.integration_enabled?(:claude_code)
    refute JSON.parse(get("/api/state").body)["integrations"]["claude_code"]
    assert_equal "400", post("/api/integration", JSON.generate("name" => "claude_code")).code
  end

  def test_theme
    assert_includes JSON.parse(get("/api/state").body)["themes"], "bunny"
    assert_equal "204", post("/api/theme", JSON.generate("theme" => "bunny")).code
    assert_equal "bunny", @cfg.theme
    assert_equal "bunny", JSON.parse(get("/api/state").body)["theme"]
    assert_equal "400", post("/api/theme", JSON.generate("theme" => "nope")).code
  end

  def test_trigger
    @bus.drain

    assert_equal "204", post("/api/trigger", JSON.generate("intention" => "fork")).code
    ev = @bus.drain

    assert_includes ev.map(&:type), :fork
    assert_equal({ once: true }, ev.find { |e| e.type == :fork }.payload)
    assert_equal "400", post("/api/trigger", JSON.generate("intention" => "nope")).code
  end

  def test_trigger_with_duration
    @bus.drain

    assert_equal "204", post("/api/trigger", JSON.generate("intention" => "think", "duration" => 8)).code
    ev = @bus.drain.find { |e| e.type == :think }

    assert_equal({ once: true, duration: 8.0 }, ev.payload)

    # Over the cap is clamped, not rejected.
    @bus.drain

    assert_equal "204", post("/api/trigger", JSON.generate("intention" => "think", "duration" => 9999)).code

    assert_in_delta Claudine::Connectors::AdminServer::MAX_TRIGGER_DURATION,
                    @bus.drain.find { |e| e.type == :think }.payload[:duration], 1e-9

    # Non-positive / non-numeric durations are rejected.
    assert_equal "400", post("/api/trigger", JSON.generate("intention" => "think", "duration" => 0)).code
    assert_equal "400", post("/api/trigger", JSON.generate("intention" => "think", "duration" => "long")).code
  end

  def test_index_page
    r = get("/")

    assert_equal "200", r.code
    assert_includes r["content-type"], "text/html"
    assert_includes r.body, "Cube"
    assert_includes r.body, "slider"
  end
end
