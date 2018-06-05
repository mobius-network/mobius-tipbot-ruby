RSpec.describe TipBot::Telegram::Command::Tip do
  let(:command_i18n_scope) { %i[telegram cmd tip] }
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_args) do
    {
      text: "Cool remark",
      from: { id: 562, username: "jack_black" },
      chat: { id: 312 },
      reply_to_message: Telegram::Bot::Types::Message.new(
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
  let(:tip_message) { TipBot::TippedMessage.new(bot_message) }
  let(:user) { TipBot::User.new(tipper[:id]) }

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

    context "when user has already tipped some message within lock period" do
      before { user.lock }

      it "renders error message" do
        expect(bot.api).to \
          receive(:answer_callback_query)
          .with(callback_query_id: subj.id, text: "You can not tip twice within an hour!")

        subject.call
      end
    end

    context "when user didn't tip this message before" do
      describe "successful scenario" do
        context 'when user is a first tipper' do
          let(:expected_text) do
            I18n.t(
              :heading,
              usernames: "@#{tipper[:username]}",
              amount: TipBot.tip_rate,
              asset: Mobius::Client.stellar_asset.code,
              scope: command_i18n_scope
            )
          end

          it "shows user's nickname in bot's message" do
            expect(bot.api).to receive(:edit_message_text).with(
              message_id: bot_message.message_id,
              chat_id: bot_message.chat.id,
              text: expected_text,
              reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup)
            )
            subject.call
          end
        end

        context "when user is a second tipper" do
          let(:expected_text) do
            I18n.t(
              :heading,
              usernames: "@peter_parker, @#{tipper[:username]}",
              amount: 2 * TipBot.tip_rate,
              asset: Mobius::Client.stellar_asset.code,
              scope: command_i18n_scope
            )
          end

          before { tip_message.tip("peter_parker") }

          it "shows both nicknames in bot's message" do
            expect(bot.api).to receive(:edit_message_text).with(
              message_id: bot_message.message_id,
              chat_id: bot_message.chat.id,
              text: expected_text,
              reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup)
            )
            subject.call
          end
        end

        context "when there were a lot of tippers" do
          let(:tippers) { %w[peter_parker jack_black jim_morrison robert_plant tony_iommi] }
          let(:expected_text) do
            I18n.t(
              :heading_for_many_tippers,
              usernames: "@robert_plant, @tony_iommi, @#{tipper[:username]}",
              amount: (tippers.size + 1) * TipBot.tip_rate,
              asset: Mobius::Client.stellar_asset.code,
              more: 3,
              scope: command_i18n_scope
            )
          end

          before { tippers.each { |u| tip_message.tip(u) } }

          it "shows only last 3 tippers nicknames in bot's message" do
            expect(bot.api).to receive(:edit_message_text).with(
              message_id: bot_message.message_id,
              chat_id: bot_message.chat.id,
              text: expected_text,
              reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup)
            )
            subject.call
          end
        end
      end
    end
  end
end
