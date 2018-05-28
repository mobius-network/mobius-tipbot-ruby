RSpec.describe TipBot::Telegram::Command::Withdraw do
  let(:errors_i18n_scope) { %i[telegram policies withdraw_command_validness_policy] }
  let(:command_i18n_scope) { %i[telegram cmd withdraw] }
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message) { Telegram::Bot::Types::Message.new(message_args) }

  subject { described_class.new(bot, message, nil) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
    allow(TipBot).to receive(:dapp).and_return(double("Mobius::Client::App", transfer: nil, pay: nil))
    allow(subject.user).to receive(:balance).and_return(10.5)
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

  context "when user's balance is zero" do
    let(:message_text) { "/withdraw" }
    before { allow(subject.user).to receive(:balance).and_return(0) }

    it "warns about empty balance" do
      subject.call
      expect(bot.api).to \
        have_received(:send_message)
        .with(
          chat_id: message.from.id,
          text: I18n.t(:balance_is_zero, scope: errors_i18n_scope)
        )
    end
  end

  context "when address is not provided" do
    let(:message_text) { "/withdraw" }

    it "sends warning message" do
      subject.call
      expect(bot.api).to \
        have_received(:send_message)
        .with(
          chat_id: message.from.id,
          text: I18n.t(:address_missing, scope: errors_i18n_scope)
        )
    end
  end

  let(:address) { "an38f" }
  let(:message_text) { "/withdraw #{address}" }

  context "when amount is not provided" do
    it "withdraws all tips" do
      subject.call

      expect(bot.api).to \
        have_received(:send_message)
        .with(
          chat_id: message.from.id,
          text: I18n.t(
            :done,
            address: address,
            amount: subject.user.balance,
            asset: Mobius::Client.asset_code,
            scope: command_i18n_scope
          )
        )
    end
  end

  context "when amount is provided" do
    let(:amount_to_withdraw) { 1.0 }
    let(:message_text) { "/withdraw #{address} #{amount_to_withdraw}" }

    it "withdraws speicified amount only" do
      subject.call

      expect(bot.api).to \
        have_received(:send_message)
        .with(
          chat_id: message.from.id,
          text: I18n.t(
            :done,
            address: address,
            amount: amount_to_withdraw,
            asset: Mobius::Client.asset_code,
            scope: command_i18n_scope
          )
        )
    end
  end

  context "when address is invalid" do
    before do
      allow(TipBot::Telegram::Service::Withdraw).to \
        receive(:call)
        .and_raise(Mobius::Client::Error::UnknownKeyPairType)
    end

    it "sends error message" do
      subject.call
      expect(bot.api).to \
        have_received(:send_message)
        .with(
          chat_id: message.from.id,
          text: I18n.t(
            :invalid_address,
            address: address,
            scope: command_i18n_scope
          )
        )
    end
  end
end
