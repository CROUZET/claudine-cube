# Config: precedence (ENV > ~/.claudine > default), safe-boot ceiling, volatile
# boost, and robust file I/O. NO hardware.
#
#   ruby test/test_config.rb
require 'json'
require 'tmpdir'
require 'logger'

ENV.delete('CLAUDINE_BRIGHTNESS')   # clean slate; each case sets it explicitly
require_relative '../lib/config'
require_relative '../config/settings'

Claudine.logger.level = ::Logger::ERROR

ALL = [true]

def check(label, got, expected)
  good = (got == expected) ||
         (got.is_a?(Numeric) && expected.is_a?(Numeric) && (got - expected).abs < 1e-9)
  puts format('%s %-48s got=%-10s exp=%s', good ? 'ok ' : 'XX ', label, got.inspect, expected.inspect)
  ALL[0] &&= good
end

# Runs a block with CLAUDINE_BRIGHTNESS set (or unset when nil), then restores.
def with_env(value)
  ENV.delete('CLAUDINE_BRIGHTNESS')
  ENV['CLAUDINE_BRIGHTNESS'] = value if value
  yield
ensure
  ENV.delete('CLAUDINE_BRIGHTNESS')
end

def write_file(path, hash)
  File.write(path, JSON.generate(hash))
end

Dir.mktmpdir do |dir|
  file = File.join(dir, '.claudine')

  # 1. default — no ENV, no file
  File.delete(file) if File.exist?(file)
  check('default (no ENV, no file)', Claudine::Config.new(path: file).brightness, Claudine::Settings::BRIGHTNESS)

  # 2. ENV wins and is honored as-is (may exceed the ceiling — deliberate)
  with_env('0.5') do
    check('ENV override honored as-is', Claudine::Config.new(path: file).brightness, 0.5)
  end

  # 3. file value used when no ENV
  write_file(file, 'brightness' => 0.12)
  check('file value (no ENV)', Claudine::Config.new(path: file).brightness, 0.12)

  # 4. ENV beats file
  write_file(file, 'brightness' => 0.12)
  with_env('0.3') do
    check('ENV beats file', Claudine::Config.new(path: file).brightness, 0.3)
  end

  # 5. file value clamped to the ceiling at load (defense vs hand-edit)
  write_file(file, 'brightness' => 0.9)
  check('file > ceiling clamped at load', Claudine::Config.new(path: file).brightness, Claudine::Config::BOOST_CEILING)

  # 6. set <= ceiling → persisted (survives a reload) and written to disk
  File.delete(file) if File.exist?(file)
  c = Claudine::Config.new(path: file)
  c.brightness = 0.1
  check('set <= ceiling persisted (reload)', Claudine::Config.new(path: file).brightness, 0.1)
  check('set <= ceiling written to file', JSON.parse(File.read(file))['brightness'], 0.1)

  # 7. set > ceiling → volatile boost: in memory yes, file unchanged, not restored
  c = Claudine::Config.new(path: file)   # boots at 0.1 (persisted above)
  c.brightness = 0.5
  check('boost in memory', c.brightness, 0.5)
  check('boost? true', c.boost?, true)
  check('boost NOT written (file stays 0.1)', JSON.parse(File.read(file))['brightness'], 0.1)
  check('boost not restored on reboot', Claudine::Config.new(path: file).brightness, 0.1)

  # 8. invalid JSON → default, no crash
  File.write(file, 'this is not json{')
  check('invalid JSON → default', Claudine::Config.new(path: file).brightness, Claudine::Settings::BRIGHTNESS)

  # 9. persisting brightness preserves other (future) keys
  write_file(file, 'brightness' => 0.1, 'theme' => 'bunny')
  c = Claudine::Config.new(path: file)
  c.brightness = 0.2
  check('other keys preserved on write', JSON.parse(File.read(file))['theme'], 'bunny')
end

puts(ALL[0] ? "\nALL OK" : "\nFAILURES")
exit(ALL[0] ? 0 : 1)
