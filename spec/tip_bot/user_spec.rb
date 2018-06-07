RSpec.describe TipBot::User do
  subject(:user) do
    described_class.new(Telegram::Bot::Types::User.new(username: nickname))
  end

  let(:rate) { TipBot.tip_rate }
  let(:nickname) { "foobar" }

  it "#lock, #locked?" do
    expect(user.locked?).to eq(false)
    user.lock
    expect(user.locked?).to eq(true)
  end
end
