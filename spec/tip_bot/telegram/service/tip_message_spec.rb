RSpec.describe TipBot::Telegram::Service::TipMessage do
  let(:message) do
    Telegram::Bot::Types::Message.new(
      text: "You should have buy some bitcoins back then",
      from: {
        id: 653,
        username: "jack_black"
      },
      chat: { id: 321 }
    )
  end

  let(:message_author) do
    TipBot::User.new(Telegram::Bot::Types::User.new(message.from))
  end
  let(:tipper_balance) { 15 }
  let(:tipper_id) { 512 }
  let(:tipper_user) do
    TipBot::User.new(Telegram::Bot::Types::User.new(id: tipper_id, username: "john_doe"))
  end

  subject { described_class.new(message, tipper_user) }

  RSpec.shared_examples "tipper zero balance" do
    it "transfers money to developer acc, locks tipper" do
      expect(TipBot.dapp).to have_received(:charge).with(TipBot.config.rate)
    end

    it "increases message author balance" do
      expect(message_author.balance).to eq(TipBot.config.rate)
    end

    it "locks tipper" do
      expect(tipper_user.locked?).to be true
    end
  end

  before do
    allow(subject.tipper).to receive(:transfer_money)
    allow(TipBot.dapp).to receive(:charge)
    allow(TipBot.dapp).to receive(:transfer)
  end

  context "when tipper and author don't have linked Stellar addresses" do
    context "when tipper has positive balance" do
      before do
        tipper_user.increment_balance(100)
        subject.call
      end

      it "doesn't touch dapp" do
        expect(TipBot.dapp).not_to have_received(:charge)
      end

      it "transfer balances" do
        expect(tipper_user.reload_balance).to eq(100 - TipBot.config.rate)
        expect(message_author.reload_balance).to eq(TipBot.config.rate)
      end

      it "doesn't lock tipper" do
        expect(tipper_user.locked?).to be false
      end
    end

    context "when tipper has zero balance" do
      before { subject.call }
      include_examples "tipper zero balance"
    end
  end

  context "when tipper pays from his own address" do
    # seed is SAKLYN2NMOPGQH6UHHFVUDYLNVXUFLK5MURHO5VONDUDMUV24EGW5EXW
    before do
      tipper_user.address = "GDZP35YTZNRVAKOAARGNBTF4ORMVKBR2WBPWUZJDVOQJOVCIEO3RHAG5"
      allow(tipper_user).to receive(:balance).and_return(tipper_balance)
    end

    context "when author of tipped message doesn't have address" do
      context "when tipper has zero balance" do
        let(:tipper_balance) { 0 }
        before { subject.call }

        include_examples "tipper zero balance"
      end

      context "when tipper has non-zero balance" do
        let(:tipper_balance) { 15 }

        before { subject.call }

        it "transfers money from user's account to developer account" do
          expect(tipper_user).to \
            have_received(:transfer_money).with(TipBot.config.rate, TipBot.app_keypair.address)
        end

        it "increments message author balance" do
          expect(message_author.balance).to eq(TipBot.config.rate)
        end

        it "doesn't lock tipper" do
          expect(tipper_user.locked?).to be false
        end
      end
    end

    context "when author of tipped message has address" do
      before do
        # seed is SAR5ME26INARWCIV7UESIFQISL5ZRUF7LIIYLONVJWAXEIYRJUM76Z6S
        message_author.address = "GADO3O3OSEFHZM2VJVVLECVFH5TVLASNXKS3WPJEQYIOQSI6QOJZWSS6"
      end

      context "when tipper has zero balance" do
        let(:tipper_balance) { 0 }
        before { subject.call }

        it "transfers money from pool to author's address" do
          expect(TipBot.dapp).to \
            have_received(:charge).with(TipBot.config.rate, target_address: message_author.address)
        end

        it "locks tipper" do
          expect(tipper_user.locked?).to be true
        end
      end

      context "when tipper has non-zero balance" do
        let(:tipper_balance) { 15 }
        before { subject.call }

        it "transfers money from tippers's account to author's account" do
          expect(tipper_user).to \
            have_received(:transfer_money).with(TipBot.config.rate, message_author.address)
        end

        it "doesn't lock tipper" do
          expect(tipper_user.locked?).to be false
        end
      end
    end
  end

  context "when bot has low balance" do
    let(:current_balance) { TipBot.config.app_balance_alert_threshold.fdiv(2) }
    before do
      allow(TipBot.config).to receive(:app_balance_alert_threshold).and_return(3.0)
      allow(TipBot.dapp).to receive(:balance).and_return(current_balance)
      allow(TipBot.dapp).to receive(:charge)
    end

    it "sends notification to admin and reraise error" do
      expect(BalanceAlertJob).to receive(:perform_async).with(:low, current_balance)
      subject.call
    end
  end

  context "when bot doesn't have sufficient balance" do
    before do
      allow(TipBot.dapp).to receive(:charge).and_raise(Mobius::Client::Error::InsufficientFunds)
    end

    it "sends notification to admin and reraise error" do
      expect(BalanceAlertJob).to receive(:perform_async).with(:exhausted)
      expect { subject.call }.to raise_error(Mobius::Client::Error::InsufficientFunds)
    end
  end
end
