# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/animation_manager"

# Smoke test: every animation in every shipped set renders across a range of instants without raising and without writing out of bounds.
# No hardware.
class AnimationsSmokeTest < Minitest::Test
  TIMES = [0.0, 0.05, 0.2, 0.5, 1.0, 2.0, 5.0, 12.0].freeze

  def setup
    @env = ENV.fetch("CLAUDINE_ANIMATION_SET", nil)
  end

  def teardown
    @env ? ENV["CLAUDINE_ANIMATION_SET"] = @env : ENV.delete("CLAUDINE_ANIMATION_SET")
  end

  def test_all_animations_render_cleanly
    total = 0
    Claudine::AnimationManager.available_sets.each do |set|
      ENV["CLAUDINE_ANIMATION_SET"] = set
      registry = Claudine::AnimationManager.new.instance_variable_get(:@registry)
      registry.each do |intention, variants|
        variants.each do |klass|
          anim = klass.new({})
          panel = TestPanels::Fake.new
          TIMES.each { |t| anim.render(t, panel) } # a raise here fails the test
          total += 1
        rescue StandardError => e
          flunk "#{set}/#{intention} (#{klass}) raised at render: #{e.message}"
        end
      end
    end

    assert_operator total, :>, 0, "no animations were found to render"
  end
end
