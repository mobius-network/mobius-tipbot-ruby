RSpec.describe TipBot::Telegram::Command::Start do
  let(:command_i18n_scope) { %i[telegram cmd start] }
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:username) { "john_doe" }
  let(:message) { Telegram::Bot::Types::Message.new(message_args) }

  subject { described_class.new(bot, message, nil) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
  end

  describe "#call" do
    context "when message is direct" do
      let(:message_args) do
        { text: "/start", from: { id: 123, username: username }, chat: { id: 123 } }
      end

      it "replies with private message" do
        subject.call
        expect(bot.api).to \
          have_received(:send_message)
          .with(
            chat_id: message.from.id,
            text: I18n.t(:private, username: username, scope: command_i18n_scope)
          )
      end
    end

    context "when message is in group" do
      let(:message_args) do
        { text: "/start", from: { id: 123, username: username }, chat: { id: 321 } }
      end

      it "replies with public message" do
        subject.call
        expect(bot.api).to \
          have_received(:send_message)
          .with(
            chat_id: message.chat.id,
            text: I18n.t(:public, username: username, scope: command_i18n_scope)
          )
      end
    end
  end
end
