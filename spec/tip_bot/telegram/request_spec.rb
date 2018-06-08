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
    end
  end
end
