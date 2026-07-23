require 'rake/testtask'

# Automated, hardware-free tests (minitest). Hardware/visual diagnostics live
# under diagnostics/ and are run by hand on the real cube — they are NOT tests.
# NB: libs is set (not appended) to avoid putting the project's lib/ on
# $LOAD_PATH — otherwise `require 'logger'` would load our lib/logger.rb instead
# of the stdlib gem. Lib files are loaded via require_relative, so lib/ need not
# be on the path.
Rake::TestTask.new(:test) do |t|
  t.libs = ['test']
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

task default: :test
