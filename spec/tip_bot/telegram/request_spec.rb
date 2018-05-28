RSpec.describe TipBot::Telegram::Request do
  let(:bot) { instance_double("Telegram::Bot::Client") }
  let(:message_id) { 785 }

  subject { described_class.new(bot, message) }

  before do
    allow(bot).to \
      receive(:api)
      .and_return(
        double("Telegram::Bot::Api", send_message: { "result" => { "message_id" => 12 } })
      )
    allow(TipBot).to receive(:dapp).and_return(double("Mobius::Client::App", transfer: nil, pay: nil))
  end

  describe "#call" do
    context "when subject is neither message, nor callback" do
      let(:message) { Object.new }

      include_examples "not triggering API"
    end

    context "when subject is message" do
      let(:message) { Telegram::Bot::Types::Message.new(message_args) }

      {
        "/start" => "Start",
        "/balance" => "Balance"
      }.each do |command, klass|
        context "when command is #{command}" do
          let(:message_args) { { text: command } }

          it "dispatches it to #{klass}" do
            expect_any_instance_of("TipBot::Telegram::Command::#{klass}".constantize).to \
              receive(:call)
            subject.call
          end
        end
      end

      describe "/tip" do
        let(:reply_to_message) do
          Telegram::Bot::Types::Message.new(
            from: {
              id: 653,
              username: "jack_black"
            },
            chat: { id: 321 }
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
                chat: { id: 321 }
              )
            end
            include_examples "not triggering API"
          end

          context "when message is sent by the bot" do
            let(:from_bot) { true }
            include_examples "not triggering API"
          end
        end
      end
    end
  end
end
