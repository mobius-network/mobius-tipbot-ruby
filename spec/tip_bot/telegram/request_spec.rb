RSpec.describe TipBot::Telegram::Request do
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_id) { 785 }

  subject { described_class.new(bot, message) }

  before do
    allow(bot).to receive(:api).and_return(double("Telegram::Bot::Api", send_message: nil))
    allow(TipBot).to receive(:dapp).and_return(double("Mobius::Client::App", transfer: nil, pay: nil))
  end

  RSpec.shared_examples "not triggering API" do
    it "doesn't trigger API" do
      subject.call
      expect(bot.api).not_to have_received(:send_message)
    end
  end

  describe "#call" do
    context "when subject is neither message, nor callback" do
      let(:message) { Object.new }

      include_examples "not triggering API"
    end

    context "when subject is message" do
      let(:message) { Telegram::Bot::Types::Message.new(message_args) }

      describe "/start" do
        let(:message_args) do
          { text: "/start", from: { id: 123, username: "john_doe" }, chat: { id: 312 } }
        end

        it "sends proper message to Telegram API" do
          subject.call
          expect(bot.api).to \
            have_received(:send_message)
            .with(chat_id: message.from.id, text: match(/I am Mobius TipBot/))
        end
      end

      describe "/balance" do
        context "when not direct message" do
          let(:message_args) do
            { text: "/balance", from: { id: 123, username: "john_doe" }, chat: { id: 312 } }
          end

          include_examples "not triggering API"
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

      describe "/tip" do
        let(:reply_to_message) do
          Telegram::Bot::Types::Message.new(
            from: {
              id: 653,
              username: "jack_black",
            },
            chat: { id: 321 },
          )
        end
        let(:from_bot) { false }
        let(:from) { { id: 123, username: "john_doe", is_bot: from_bot } }
        let(:message_args) do
          {
            message_id: message_id,
            text: "/tip",
            from: from,
            chat: { id: 321 },
            reply_to_message: reply_to_message
          }
        end

        context "when tipping is not allowed" do
          context "when message is not a reply" do
            let(:reply_to_message) { nil }
            include_examples "not triggering API"
          end

          context "when message is reply to itself" do
            let(:reply_to_message) do
              Telegram::Bot::Types::Message.new(
                from: { id: from[:id], username: "jack_black" },
                chat: { id: 321 },
              )
            end
            include_examples "not triggering API"
          end

          context "when message is sent by the bot" do
            let(:from_bot) { true }
            include_examples "not triggering API"
          end
        end

        context "when tipping is allowed" do
          before { subject.call }

          it "automatically tips message once" do
            expect(TipBot::TippedMessage.new(reply_to_message).count).to eq(1)
          end

          it "sends proper message to Telegram API" do
            expect(bot.api).to \
              have_received(:send_message)
              .with(
                chat_id: message.chat.id,
                text: match(/\@#{message.from.username} highly appreciates/),
                reply_to_message_id: message.reply_to_message.message_id,
                reply_markup: kind_of(Telegram::Bot::Types::InlineKeyboardMarkup)
              )
          end
        end
      end

      describe "/withdraw" do
        context "when not direct message" do
          let(:message_args) do
            { text: "/withdraw an38f", from: { id: 123, username: "john_doe" }, chat: { id: 312 } }
          end

          include_examples "not triggering API"
        end

        context "when direct message" do
          let(:message_args) do
            { text: message_text, from: { id: 123, username: "john_doe" }, chat: { id: 123 } }
          end

          context "when address is not provided" do
            let(:message_text) { "/withdraw" }

            it "sends warning message" do
              subject.call
              expect(bot.api).to \
                have_received(:send_message)
                .with(chat_id: message.from.id, text: /Provide target address to withdraw!/)
            end
          end

          context "when address is provided" do
            let(:address) { "an38f" }
            let(:message_text) { "/withdraw #{address}" }

            context "when user's balance is zero" do
              before { allow_any_instance_of(TipBot::User).to receive(:balance).and_return(0) }

              it "warns about empty balance" do
                subject.call
                expect(bot.api).to \
                  have_received(:send_message)
                  .with(chat_id: message.from.id, text: /Nothing to withdraw/)
              end
            end

            context "when user's balance is positive" do
              before { allow_any_instance_of(TipBot::User).to receive(:balance).and_return(1000) }

              context "when address is valid" do
                it "withdraws money" do
                  expect_any_instance_of(TipBot::User).to receive(:withdraw).with(address)
                  subject.call
                end

                it "sends success message" do
                  subject.call
                  expect(bot.api).to \
                    have_received(:send_message)
                    .with(chat_id: message.from.id, text: /Your tips has been successfully withdrawn to #{address}/)
                end
              end

              context "when address is invalid" do
                it "sends error message" do
                  allow_any_instance_of(TipBot::User).to \
                    receive(:withdraw).and_raise(Mobius::Client::Error::UnknownKeyPairType)

                  subject.call
                  expect(bot.api).to \
                    have_received(:send_message)
                    .with(chat_id: message.from.id, text: /Invalid target address: #{address}/)
                end
              end
            end
          end
        end
      end
    end
  end
end
