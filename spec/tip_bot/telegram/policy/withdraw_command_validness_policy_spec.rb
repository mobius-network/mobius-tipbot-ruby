require "tram/policy/rspec"

RSpec.describe WithdrawCommandValidnessPolicy do
  let(:address) { "some_stellar_address" }
  let(:amount) { 10 }
  let(:user_balance) { 15 }

  subject do
    described_class[
      nil, # we don't provide actual command instance for easier stubbing
      destination_address: address,
      amount_to_withdraw: amount,
      user_balance: user_balance
    ]
  end

  it { is_expected.to be_valid }

  context "when user's balance is zero" do
    let(:user_balance) { 0 }
    it { is_expected.to be_invalid }
  end

  context "when user's balance is insufficient" do
    let(:user_balance) { amount / 2 }
    it { is_expected.to be_invalid }
  end

  context "when address is not provided" do
    let(:address) { nil }
    it { is_expected.to be_invalid }
  end

  context "when amount is invalid" do
    let(:amount) { "12g" }
    it { is_expected.to be_invalid }
  end

  context "when amount is negative" do
    let(:amount) { "-12.5" }
    it { is_expected.to be_invalid }
  end
end
