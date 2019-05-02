RSpec.describe TipBot::Telegram::Service::CreateAddress do
  let(:user) { TipBot::User.new(id: 3242, username: "john_doe") }
  let(:address) { "GD5HCGTPNJIKSAAKUYQCOFOHL2YJVPQTUNKWDOLOQJLPDN6LWNVY6ART" }
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
