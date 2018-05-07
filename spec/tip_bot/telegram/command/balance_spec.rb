RSpec.describe TipBot::Telegram::Command::Balance do
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_args) do
    {
      text: "/balance",
      from: { id: 562, username: "jack_black" },
      chat: { id: 312 }
    }
  end
  let(:message) { Telegram::Bot::Types::Message.new(message_args) }

  subject { described_class.new(bot, message, nil) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
  end

  describe "#call" do
    context "when not direct message" do
      let(:message_args) do
        { text: "/balance", from: { id: 123, username: "john_doe" }, chat: { id: 312 } }
      end

      it "doesn't trigger API" do
        subject.call
        expect(bot.api).not_to have_received(:send_message)
      end
    end

    context "when direct message" do
      let(:message_args) do
        { text: "/balance", from: { id: 123, username: "john_doe" }, chat: { id: 123 } }
      end

      context "when user has Stellar address" do
        before do
          allow_any_instance_of(TipBot::User).to \
            receive(:address).and_return("some_truthy_value")
        end

        it "sends proper message to Telegram API" do
          subject.call
          expect(bot.api).to \
            have_received(:send_message)
            .with(chat_id: message.from.id, text: match(/all tips are instantly sent/))
        end
      end

      context "when user has no Stellar address" do
        before do
          allow_any_instance_of(TipBot::User).to receive(:address).and_return(nil)
        end

        it "sends proper message to Telegram API" do
          subject.call
          expect(bot.api).to \
            have_received(:send_message)
            .with(
              chat_id: message.from.id,
              text: match(/balance awaiting for withdraw/)
            )
        end
      end
    end
  end
end
