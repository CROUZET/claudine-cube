# ClaudeCode connector honors the integration gate: when the `claude_code`
# integration is disabled in Config, POSTs still get a 204 (hooks never error)
# but are NOT pushed onto the bus. NO hardware.
#
#   ruby test/test_claude_code_gate.rb
require 'net/http'
require 'tmpdir'
require 'logger'

ENV.delete('CLAUDINE_BRIGHTNESS')
require_relative '../lib/event'
require_relative '../lib/event_bus'
require_relative '../lib/config'
require_relative '../lib/connectors/claude_code'

Claudine.logger.level = ::Logger::ERROR

PORT = 9392
ALL  = [true]

def check(label, cond)
  puts format('%s %s', cond ? 'ok ' : 'XX ', label)
  ALL[0] &&= cond
end

def post(type)
  Net::HTTP.new('127.0.0.1', PORT).post("/event/#{type}", '')
end

Dir.mktmpdir do |dir|
  cfg = Claudine::Config.new(path: File.join(dir, '.claudine'))
  bus = Claudine::EventBus.new
  srv = Claudine::Connectors::ClaudeCode.new(bus: bus, port: PORT, config: cfg)
  srv.start

  # wait for the listener (the warm-up POST also seeds one event we drain below)
  30.times do
    begin
      post('warmup'); break
    rescue Errno::ECONNREFUSED
      sleep 0.05
    end
  end

  begin
    # enabled by default → the event reaches the bus (push happens before the 204)
    bus.drain
    r = post('user_prompt')
    check('enabled → 204', r.code == '204')
    check('enabled → event pushed', bus.drain.map(&:type).include?(:user_prompt))

    # disabled → still 204, but nothing pushed
    cfg.set_integration('claude_code', false)
    r = post('user_prompt')
    check('disabled → 204', r.code == '204')
    check('disabled → nothing pushed', bus.drain.empty?)

    # re-enabled → pushes again
    cfg.set_integration('claude_code', true)
    post('stop')
    check('re-enabled → event pushed', bus.drain.map(&:type).include?(:stop))
  ensure
    srv.stop
  end
end

puts(ALL[0] ? "\nALL OK" : "\nFAILURES")
exit(ALL[0] ? 0 : 1)
