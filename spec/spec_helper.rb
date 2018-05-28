require "bundler/setup"
require "telegram/bot"
require "redis-namespace"
require "simplecov"
require "simplecov-console"
require "vcr"
require "pry-byebug"

SimpleCov.formatter = SimpleCov::Formatter::Console if ENV["CC_TEST_REPORTER_ID"]
SimpleCov.start do
  add_filter "spec"
  track_files "{.,tip_bot}/**/*.rb"
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

require "./tip_bot"

I18n.load_path = Dir.glob(File.join(File.dirname(__FILE__), "../locales/*.yml"))
I18n.locale = :en

TipBot.redis = Redis::Namespace.new(:tipbot_test, redis: Redis.new)

RSpec.shared_examples "not triggering API" do
  it "doesn't trigger API" do
    subject.call
    expect(bot.api).not_to have_received(:send_message)
  end
end

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
