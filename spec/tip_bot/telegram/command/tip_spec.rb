RSpec.describe TipBot::Telegram::Command::Tip do
  let(:command_i18n_scope) { %i[telegram cmd tip] }
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_args) do
    {
      from: { id: 562, username: "jack_black" },
      chat: { id: 312 },
      reply_to_message: Telegram::Bot::Types::Message.new(
        text: "Cool remark",
        from: { id: 235, username: "frank_sinatra" },
        chat: { id: 312 }
      )
    }
  end
  let(:bot_message) { Telegram::Bot::Types::Message.new(message_args) }
  let(:tipper) { { id: 123, username: "john_doe" } }
  let(:subj) do
    Telegram::Bot::Types::CallbackQuery.new(id: 11, from: tipper, message: bot_message)
  end
  let(:tip_message) { TipBot::TippedMessage.new(bot_message.reply_to_message) }
  let(:user) { TipBot::User.new(Telegram::Bot::Types::User.new(tipper)) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
    allow(TipBot).to receive(:dapp).and_return(double("Mobius::Client::App", pay: nil))
  end

  subject { described_class.new(bot, subj.message, subj) }

  describe "#call" do
    context "when user has already tipped this message" do
      before { tip_message.tip(tipper[:username]) }

      it "renders error message" do
        expect(bot.api).to \
          receive(:answer_callback_query)
          .with(callback_query_id: subj.id, text: "You tipped this message already")

        subject.call
      end
    end

    context "when user has already tipped some message within lock period" do
      before { user.lock }

      it "renders error message" do
        expect(bot.api).to \
          receive(:answer_callback_query)
          .with(callback_query_id: subj.id, text: "You can not tip twice within an hour!")

        subject.call
      end
    end
  end
end
