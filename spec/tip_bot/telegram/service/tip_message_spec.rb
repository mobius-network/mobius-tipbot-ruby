# All Stellar accounts used here were created manually, with all required
# trustlines, cosigners etc.
RSpec.describe TipBot::Telegram::Service::TipMessage, order: :defined do
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

  let(:message_author) { TipBot::User.new(message.from.id) }
  let(:tipper_id) { 512 }
  let(:tipper_user) { TipBot::User.new(tipper_id) }

  # Both deposit and credit account are pre-created, funded, and deposit account is
  # set to be a cosigner for the credit account
  #
  # Because of this preset we don't have fully isolated specs, because balances are
  # not cleared before each of them
  let(:deposit_account) do
    # address is GCXIPNBIRZN6MSQVCGFTB363ZGXP2HAJQLQFYY4UXQYDTC65WDU67JYM
    Mobius::Client::Blockchain::Account.new(
      Stellar::KeyPair.from_seed(
        "SDO2XY3JZ5ZJNGRT7PHOIERPBLYRTKSDHYZO3CFIITKFMF7VFGI4HLX7"
      )
    )
  end
  let(:credit_account) do
    # seed is SC7CSK6M2J7VCMOWNFE72PDY7DNLYZ37GWAV4X33NYLI7TPOYZFU22R5
    Mobius::Client::Blockchain::Account.new(
      Stellar::KeyPair.from_address(
        "GBNVKV6LYJOC5SXX43TKCCYPZJEPU6O4CWCVAVRAYN5ILHVE6RXM7RTM"
      )
    )
  end

  subject do
    described_class.new(
      message,
      Telegram::Bot::Types::User.new(id: tipper_id, username: "john_doe")
    )
  end

  before do
    TipBot.dapp = Mobius::Client::App.new(
      deposit_account.keypair.seed,
      credit_account.keypair.address
    )
  end

  describe "#call" do
    context "when tipper and author don't have linked Stellar addresses" do
      it do
        VCR.use_cassette("tip_message/no_addresses") do
          subject.call
          expect(deposit_account.balance).to eq(TipBot.tip_rate)
          expect(credit_account.balance).to eq(1000.0 - TipBot.tip_rate)
        end
      end
    end

    context "when tipper pays from his own address" do
      # seed is SAKLYN2NMOPGQH6UHHFVUDYLNVXUFLK5MURHO5VONDUDMUV24EGW5EXW
      before { tipper_user.address = "GDZP35YTZNRVAKOAARGNBTF4ORMVKBR2WBPWUZJDVOQJOVCIEO3RHAG5" }

      context "when author of tipped message doesn't have address" do
        it do
          VCR.use_cassette("tip_message/tip_from_tipper_address") do
            subject.call

            expect(tipper_user.stellar_account.balance).to eq(1000.0 - TipBot.tip_rate)
            expect(deposit_account.balance).to eq(2 * TipBot.tip_rate)
            expect(credit_account.balance).to eq(1000.0 - TipBot.tip_rate)
          end
        end
      end

      context "when author of tipped message has address" do
        # seed is SAR5ME26INARWCIV7UESIFQISL5ZRUF7LIIYLONVJWAXEIYRJUM76Z6S
        before { message_author.address = "GADO3O3OSEFHZM2VJVVLECVFH5TVLASNXKS3WPJEQYIOQSI6QOJZWSS6" }

        it do
          VCR.use_cassette("tip_message/tip_from_tipper_address_to_user_address") do
            subject.call

            expect(tipper_user.stellar_account.balance).to eq(1000.0 - 2 * TipBot.tip_rate)
            expect(message_author.stellar_account.balance).to eq(TipBot.tip_rate)
            # these shouldn't change
            expect(deposit_account.balance).to eq(2 * TipBot.tip_rate)
            expect(credit_account.balance).to eq(1000.0 - TipBot.tip_rate)
          end
        end
      end
    end

    context "when bot has low balance" do
      let(:current_balance) { TipBot.balance_alert_threshold.fdiv(2) }
      before do
        allow(TipBot).to receive(:balance_alert_threshold).and_return(3.0)
        allow(TipBot.dapp).to receive(:balance).and_return(current_balance)
        allow(TipBot.dapp).to receive(:pay)
      end

      it "sends notification to admin and reraise error" do
        expect(BalanceAlertJob).to receive(:perform_async).with(:low, current_balance)
        subject.call
      end
    end

    context "when bot doesn't have sufficient balance" do
      before do
        allow(TipBot.dapp).to receive(:pay).and_raise(Mobius::Client::Error::InsufficientFunds)
      end

      it "sends notification to admin and reraise error" do
        expect(BalanceAlertJob).to receive(:perform_async).with(:exhausted)
        expect { subject.call }.to raise_error(Mobius::Client::Error::InsufficientFunds)
      end
    end
  end
end
