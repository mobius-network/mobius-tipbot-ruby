require "bundler/setup"
require "telegram/bot"
require "redis-namespace"
require "simplecov"
require "simplecov-console"
require "vcr"
require "pry-byebug"
require "dotenv/load"

ENV["MOBIUS_TIPBOT_ENVIRONMENT"] = "test"

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

    TipBot.config.app_private_key = 'SB2AEDWD7JWMCIS5ZNE5FQBS5Y7TXSGJ3UZFZ5MGUM5F652FC2M7TICF' # GC3HBXXIBPAJW4QAKJHIQEEKKWP5UNB27WNWIBEGKFFBV3U6D54XOGVC
    TipBot.config.credit_address = 'GADH5RG33KTIWYUZ7IRG5VVY6K4RRMZAUXA5CL6SJM2UXXBQ5RHWPV3Z'  # SAIOX5UDOBHLFH32QKRGTQ52DP7TGQDLRDGMN76KNXY23AR2E37VBYJI
    TipBot.config.asset_code = 'MOBI'
    TipBot.config.asset_issuer = 'GDRWBLJURXUKM4RWDZDTPJNX6XBYFO3PSE4H4GPUL6H6RCUQVKTSD4AT'
  end

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  Kernel.srand config.seed
end
