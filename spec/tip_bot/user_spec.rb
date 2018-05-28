RSpec.describe TipBot::User do
  subject(:user) { described_class.new(nickname) }
  let(:rate) { TipBot.tip_rate }
  let(:nickname) { "foobar" }

  it "#lock, #locked?" do
    expect(user.locked?).to eq(false)
    user.lock
    expect(user.locked?).to eq(true)
  end
end
