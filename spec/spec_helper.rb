require "bundler/setup"
require "telegram/bot"
require "redis-namespace"
require "simplecov"
require "simplecov-console"
require "./tip_bot"

I18n.load_path = Dir.glob(File.join(File.dirname(__FILE__), "../locales/*.yml"))
I18n.locale = :en

TipBot.redis = Redis::Namespace.new(:tipbot_test, redis: Redis.new)

SimpleCov.formatter = SimpleCov.formatter = SimpleCov::Formatter::Console if ENV["CC_TEST_REPORTER_ID"]
SimpleCov.start

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before do
    # Replacement to flushdb
    keys = TipBot.redis.keys("*")
    TipBot.redis.del(keys) if keys.any?
  end

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
