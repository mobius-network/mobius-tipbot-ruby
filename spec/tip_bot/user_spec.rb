RSpec.describe TipBot::User do
  subject(:user) { described_class.new(nickname, dapp) }

  let(:dapp) { instance_double(Mobius::Client::App) }
  let(:rate) { TipBot.tip_rate }
  let(:nickname) { "foobar" }

  it "#tip", "address not linked" do
    expect(dapp).to receive(:pay).with(rate, target_address: nil).and_return(true)
    user.tip
    expect(user.balance).to eq(rate)
  end

  it "#tip", "address linked" do
    TipBot.redis.hset("address", nickname, "addr")
    expect(dapp).to receive(:pay).with(rate, target_address: "addr").and_return(true)
    user.tip
    expect(user.balance).to eq(0)
  end
end
