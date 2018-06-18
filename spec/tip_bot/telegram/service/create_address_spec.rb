RSpec.describe TipBot::Telegram::Service::CreateAddress do
  let (:user) { TipBot::User.new(id: 3242, username: "john_doe") }
  let(:address) { "GC2PDSGZRZJ66H2F5TO7BGF6AZ5VQJZMTDWBQHKJX52FDH7TYW4CEMBP" }
  let(:amount) { 10 }

  describe ".call" do
    it "returns hash with newly generated address and txe to sign" do
      VCR.use_cassette("create_address/call") do
        call_result = described_class.call(user, address, amount)

        expect(call_result[:user_address]).to match(/\AG[A-Z\d]+\Z/)
        expect(call_result[:txe]).to be_kind_of(Stellar::TransactionEnvelope)
      end
    end
  end
end

