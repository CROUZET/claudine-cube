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

# On-cube diagnostics — manual utilities that drive the real hardware, NOT the
# test suite. Each shells out to its script under diagnostics/. Run with the
# cube plugged in (and, for gem access, via `bundle exec`).
namespace :diagnostics do
  desc 'One color per face — checks the chain order + mapping (needs the cube)'
  task :faces do
    ruby 'diagnostics/cube_faces.rb'
  end

  desc 'Light the 8 shared edges, both sides — edge calibration (needs the cube)'
  task :edge do
    ruby 'diagnostics/cube_edge.rb'
  end

  desc 'Preview animations on the cube — INTENTIONS="think handled" to filter (needs the cube)'
  task :preview do
    ruby 'diagnostics/cube_preview.rb', *ENV['INTENTIONS'].to_s.split
  end

  desc 'Brightness / current stress, DC vs USB (needs the cube)'
  task :stress do
    ruby 'diagnostics/cube_stress.rb'
  end
end
