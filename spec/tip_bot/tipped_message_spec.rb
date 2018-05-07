RSpec.describe TipBot::TippedMessage do
  subject do
    described_class.new(
      Telegram::Bot::Types::Message.new(
        message_id: 123,
        chat: { id: 324 }
      )
    )
  end

  # Although we don't test `tip` method explicitly here,
  # it will be in fact tested through other methods' specs
  before do
    subject.tip("john_doe", 2)
    subject.tip("jack_black", 3)
  end

  describe "#balance" do
    it "returns tips balance for given message" do
      expect(subject.balance).to eq(5)
    end
  end

  describe "#tipped?" do
    context "when user with given nickname tipped given message" do
      it "returns true" do
        expect(subject.tipped?("john_doe")).to be true
        expect(subject.tipped?("jack_black")).to be true
      end
    end

    context "when user with given nickname didn't tip given message" do
      it "returns false" do
        expect(subject.tipped?("peter_parker")).to be false
      end
    end
  end

  describe "#count" do
    it "returns overall tips count for the given message" do
      expect(subject.count).to eq(2)
    end
  end
end
