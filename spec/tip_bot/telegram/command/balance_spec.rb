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
  let(:user) { TipBot::User.new(message.from.username) }

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
          # seed is SASMROFT6E6QAKOLU46GLN4U2VHMEHMKJNWAVDGSQW5F3X2C7DJJHR22
          user.address = "GD5HCGTPNJIKSAAKUYQCOFOHL2YJVPQTUNKWDOLOQJLPDN6LWNVY6ART"
        end

        it "takes balance from Stellar" do
          VCR.use_cassette("balance/with_address") do
            subject.call
            expect(bot.api).to \
              have_received(:send_message)
              .with(
                chat_id: message.from.id,
                text: match(/^Your balance awaiting for withdraw is 1000\.0 MOBI/)
              )
          end
        end
      end

      context "when user has no Stellar address" do
        before do
          user.address = nil
          user.increment_balance(4)
        end

        it "takes balance from redis" do
          subject.call
          expect(bot.api).to \
            have_received(:send_message)
            .with(
              chat_id: message.from.id,
              text: match(/^Your balance awaiting for withdraw is 4\.0 MOBI/)
            )
        end
      end
    end
  end
end
