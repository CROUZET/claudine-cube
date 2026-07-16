require 'rubyserial'

# rubyserial 0.6.0 on macOS only knows the standard baud rates up to 230400
# (see osx_constants.rb). But macOS accepts higher rates (460800,
# 921600, 1M, 2M...) by writing the raw value into c_ispeed/c_ospeed
# before tcsetattr. We extend the table to let any integer through.
#
# On Linux the table contains special flags (B921600 etc.), we leave it alone.
unless RubySerial::ON_LINUX
  RubySerial::Posix::BAUDE_RATES.default_proc = ->(_h, k) { k }
end
