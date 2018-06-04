RSpec.describe TipBot::Telegram::Command::Withdraw do
  let(:command_i18n_scope) { %i[telegram cmd withdraw] }
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message) { Telegram::Bot::Types::Message.new(message_args) }

  subject { described_class.new(bot, message, nil) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
    allow_any_instance_of(WithdrawCommandValidnessPolicy).to receive(:valid?).and_return(true)
  end

  context "when not direct message" do
    let(:message_args) do
      { text: "/withdraw an38f", from: { id: 123, username: "john_doe" }, chat: { id: 312 } }
    end

    include_examples "not triggering API"
  end

  let(:message_args) do
    { text: message_text, from: { id: 123, username: "john_doe" }, chat: { id: 123 } }
  end

  let(:address) { "an38f" }
  let(:amount_to_withdraw) { 1.0 }
  let(:message_text) { "/withdraw #{address} #{amount_to_withdraw}" }

  it "calls corresponding service" do
    expect(TipBot::Telegram::Service::Withdraw).to \
      receive(:call)
      .with(subject.user, address, amount_to_withdraw&.to_f)
    subject.call
  end

  {
    Mobius::Client::Error::UnknownKeyPairType => [:invalid_address, {}],
    Mobius::Client::Error::TrustlineMissing => [
      :trustline_missing,
      { code: Mobius::Client.asset_code, issuer: Mobius::Client.asset_issuer }
    ],
    Mobius::Client::Error::AccountMissing => [:account_missing, {}]
  }.each do |error_class, message_i18n_args|
    context "when #{error_class} is raised" do
      let(:expected_response) do
        I18n.t(
          message_i18n_args.first,
          message_i18n_args[1].merge(
            address: address,
            scope: command_i18n_scope
          )
        )
      end

      before do
        allow(TipBot::Telegram::Service::Withdraw).to receive(:call).and_raise(error_class)
      end

      it "sends error message" do
        subject.call
        expect(bot.api).to \
          have_received(:send_message)
          .with(chat_id: message.from.id, text: expected_response)
      end
    end
  end
end
