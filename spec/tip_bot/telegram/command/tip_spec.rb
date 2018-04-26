RSpec.describe TipBot::Telegram::Command::Tip do
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_args) do
    {
      text: "Cool remark",
      from: { id: 562, username: "jack_black" },
      chat: { id: 312 },
      reply_to_message: Telegram::Bot::Types::Message.new(from: { id: 235, username: "frank_sinatra" })
    }
  end
  let(:bot_message) { Telegram::Bot::Types::Message.new(message_args) }
  let(:tipper) { { id: 123, username: "john_doe" } }
  let(:subj) do
    Telegram::Bot::Types::CallbackQuery.new(id: 11, from: tipper, message: bot_message)
  end
  let(:tip_message) { TipBot::TippedMessage.new(bot_message.message_id) }

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
          .with(callback_query_id: subj.id, text: "You cannot tip twice the same message!")

        subject.call
      end
    end

    context "when user didn't tip this message before" do
      describe "successful scenario" do
        context "when user is a second tipper" do
          before { tip_message.tip("peter_parker") }

          it "shows both nicknames in bot's message" do
            expect(bot.api).to receive(:edit_message_text).with(
              message_id: bot_message.message_id,
              chat_id: bot_message.chat.id,
              text: match(/\@peter_parker, \@#{tipper[:username]} highly appreciate this message/),
              reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup),
            )
            subject.call
          end
        end

        context "when there were a lot of tippers" do
          before do
            tip_message.tip("peter_parker")
            tip_message.tip("jack_black")
            tip_message.tip("jim_morrison")
            tip_message.tip("robert_plant")
            tip_message.tip("tony_iommi")
          end

          it "shows only last 3 tippers nicknames in bot's message" do
            expect(bot.api).to receive(:edit_message_text).with(
              message_id: bot_message.message_id,
              chat_id: bot_message.chat.id,
              text: match(/\@robert_plant, \@tony_iommi, \@#{tipper[:username]} and 3 others highly appreciate this message/),
              reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup),
            )
            subject.call
          end
        end
      end
    end
  end
end
