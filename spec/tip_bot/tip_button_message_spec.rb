RSpec.describe TipBot::TipButtonMessage do
  let(:telegram_message) do
    Telegram::Bot::Types::Message.new(
      chat: { id: -11243563 },
      from: {
        id: 983,
        username: "frank_sinatra"
      }
    )
  end

  let(:tipped_message) do
    TipBot::TippedMessage.new(telegram_message)
  end

  subject { described_class.new(tipped_message) }

  describe "#heading_text" do
    subject { described_class.new(tipped_message).heading_text }

    context "when there is one tipper" do
      before { tipped_message.tip("john_doe") }

      it { is_expected.to match(/^@john_doe/) }
    end

    context "when there are less than or equal to 3 tippers" do
      before do
        tipped_message.tip("john_doe")
        tipped_message.tip("robert_plant")
        tipped_message.tip("tony_iommi")
      end

      it { is_expected.to match(/^@john_doe, @robert_plant, @tony_iommi/) }
    end

    context "when there are more than 3 tippers" do
      before do
        tipped_message.tip("john_doe")
        tipped_message.tip("robert_plant")
        tipped_message.tip("tony_iommi")
        tipped_message.tip("piter_parker")
        tipped_message.tip("charles_xavier")
      end

      it { is_expected.to match(/^@tony_iommi, @piter_parker, @charles_xavier and 2 others/) }
    end
  end

  describe "#button_layout" do
    before do
      tipped_message.tip("john_doe")
      tipped_message.tip("robert_plant")
    end

    it "uses TipKbMarkup class" do
      expect(TipBot::Telegram::TipKbMarkup).to receive(:call).with(2)
      subject.button_layout
    end
  end
end
