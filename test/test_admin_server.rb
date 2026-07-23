# AdminServer: the control-plane HTTP API, isolated (no Panel → no serial/hardware).
# Starts WEBrick on a test port against a temp Config, then drives it over HTTP.
#
#   ruby test/test_admin_server.rb
require 'net/http'
require 'json'
require 'tmpdir'
require 'logger'

ENV.delete('CLAUDINE_BRIGHTNESS')
require_relative '../lib/event'
require_relative '../lib/event_bus'
require_relative '../lib/config'
require_relative '../lib/status'
require_relative '../lib/connectors/admin_server'

Claudine.logger.level = ::Logger::ERROR

PORT = 9391   # test port, distinct from the real 9293
ALL  = [true]

def check(label, cond)
  puts format('%s %s', cond ? 'ok ' : 'XX ', label)
  ALL[0] &&= cond
end

def req(method, path, body = nil)
  http = Net::HTTP.new('127.0.0.1', PORT)
  r =
    case method
    when :get  then http.get(path)
    when :post
      h = { 'Content-Type' => 'application/json' }
      http.post(path, body, h)
    end
  r
end

Dir.mktmpdir do |dir|
  cfg = Claudine::Config.new(path: File.join(dir, '.claudine'))
  status = Claudine::Status.new
  status.publish(state: 'working', animation: 'Think', uptime_s: 5)
  bus = Claudine::EventBus.new
  srv = Claudine::Connectors::AdminServer.new(config: cfg, status: status, bus: bus, port: PORT)
  srv.start

  # wait for the listener to come up
  30.times do
    begin
      req(:get, '/api/state'); break
    rescue Errno::ECONNREFUSED
      sleep 0.05
    end
  end

  begin
    # GET /api/state
    r = req(:get, '/api/state')
    check('GET /api/state → 200', r.code == '200')
    check('GET /api/state → application/json', r['content-type'].to_s.include?('application/json'))
    state = JSON.parse(r.body)
    check('state has brightness', state.key?('brightness'))
    check('state has boost_ceiling 0.25', state['boost_ceiling'] == 0.25)
    check('state has integrations', state['integrations'].is_a?(Hash) && state['integrations'].key?('claude_code'))

    # POST /api/brightness (<= ceiling) applies to Config
    r = req(:post, '/api/brightness', JSON.generate('value' => 0.1))
    check('POST brightness 0.1 → 204', r.code == '204')
    check('config.brightness == 0.1', (cfg.brightness - 0.1).abs < 1e-9)

    # reflected in a fresh state read
    state = JSON.parse(req(:get, '/api/state').body)
    check('state reflects 0.1', (state['brightness'] - 0.1).abs < 1e-9)

    # bad input → 400
    r = req(:post, '/api/brightness', JSON.generate('nope' => 1))
    check('POST without value → 400', r.code == '400')
    r = req(:post, '/api/brightness', 'not json')
    check('POST invalid JSON → 400', r.code == '400')

    # POST /api/integration toggles a source integration
    r = req(:post, '/api/integration', JSON.generate('name' => 'claude_code', 'enabled' => false))
    check('POST integration off → 204', r.code == '204')
    check('config integration disabled', cfg.integration_enabled?(:claude_code) == false)
    state = JSON.parse(req(:get, '/api/state').body)
    check('state reflects integration off', state['integrations']['claude_code'] == false)
    r = req(:post, '/api/integration', JSON.generate('name' => 'claude_code', 'enabled' => true))
    check('POST integration on → 204', r.code == '204')
    check('config integration re-enabled', cfg.integration_enabled?(:claude_code) == true)

    # bad integration input → 400
    r = req(:post, '/api/integration', JSON.generate('name' => 'claude_code'))
    check('integration without enabled → 400', r.code == '400')

    # POST /api/theme switches the active animation set
    state = JSON.parse(req(:get, '/api/state').body)
    check('state has theme', state.key?('theme'))
    check('state has themes list', state['themes'].is_a?(Array) && state['themes'].include?('bunny'))
    r = req(:post, '/api/theme', JSON.generate('theme' => 'bunny'))
    check('POST theme bunny → 204', r.code == '204')
    check('config theme == bunny', cfg.theme == 'bunny')
    check('state reflects theme', JSON.parse(req(:get, '/api/state').body)['theme'] == 'bunny')
    r = req(:post, '/api/theme', JSON.generate('theme' => 'nope'))
    check('unknown theme → 400', r.code == '400')

    # /api/state advertises the intention vocabulary (for the trigger buttons)
    check('state has intentions list', JSON.parse(req(:get, '/api/state').body)['intentions'].include?('fork'))

    # POST /api/trigger pushes the intention onto the bus
    bus.drain
    r = req(:post, '/api/trigger', JSON.generate('intention' => 'fork'))
    check('POST trigger fork → 204', r.code == '204')
    check('trigger pushed :fork onto the bus', bus.drain.map(&:type).include?(:fork))
    r = req(:post, '/api/trigger', JSON.generate('intention' => 'nope'))
    check('unknown intention → 400', r.code == '400')

    # GET /api/status returns the published runtime snapshot (read-only)
    r = req(:get, '/api/status')
    check('GET /api/status → 200', r.code == '200')
    sdata = JSON.parse(r.body)
    check('status reflects published snapshot', sdata['state'] == 'working' && sdata['animation'] == 'Think')

    # GET / serves the HTML page
    r = req(:get, '/')
    check('GET / → 200', r.code == '200')
    check('GET / → text/html', r['content-type'].to_s.include?('text/html'))
    check('GET / body looks like the admin page', r.body.include?('Cube') && r.body.include?('slider'))
  ensure
    srv.stop
  end
end

puts(ALL[0] ? "\nALL OK" : "\nFAILURES")
exit(ALL[0] ? 0 : 1)
