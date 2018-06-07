require "tram/policy/rspec"

RSpec.describe TipCommandValidnessPolicy do
  let(:amount) { 10 }
  let(:message_to_tip_author) { { id: 827, is_bot: false } }
  let(:message_args) do
    {
      chat: { id: -1934501470234 },
      text: "You really should buy bitcoins back then",
      from: message_to_tip_author
    }
  end
  let(:tipper_username) { "john_doe" }
  let(:message_to_tip) { Telegram::Bot::Types::Message.new(message_args) }
  let(:tipper) do
    TipBot::User.new(
      Telegram::Bot::Types::User.new(id: 123, username: tipper_username)
    )
  end

  subject { described_class[message_to_tip: message_to_tip, amount: amount, tipper: tipper] }

  it { is_expected.to be_valid }

  context "when tipper doesn't have username" do
    let(:tipper_username) { nil }
    it { is_expected.to be_invalid }
  end

  context "when command sent not in reply" do
    let(:message_to_tip) { nil }
    it { is_expected.to be_invalid }
  end

  context "when user tries to tip themselves" do
    let(:message_to_tip_author) { { id: tipper.id } }
    it { is_expected.to be_invalid }
  end

  context "when user already tipped this message" do
    before do
      TipBot::TippedMessage.new(message_to_tip).tip(tipper_username)
    end
    it { is_expected.to be_invalid }
  end

  context "when user tries to tip a bot" do
    let(:message_to_tip_author) { { id: 827, is_bot: true } }
    it { is_expected.to be_invalid }
  end

  context "when amount is not provided" do
    let(:amount) { nil }
    it { is_expected.to be_valid }
  end

  context "when provided amount is NaN" do
    let(:amount) { "91f" }
    it { is_expected.to be_invalid }
  end

  context "when provided amount is negative" do
    let(:amount) { "-5.5" }
    it { is_expected.to be_invalid }
  end

  context "when user tipped recently" do
    before { tipper.lock }
    it { is_expected.to be_invalid }
  end
end
