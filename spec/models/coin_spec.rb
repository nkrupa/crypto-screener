require 'rails_helper'

RSpec.describe Coin, type: :model do

  describe '#on_bittrex?' do
    it "is true when BitTrex included" do
      subject.exchanges << "BitTrex"
      expect(subject.on_bittrex?).to be_truthy
    end

    it "is false when not included" do
      expect(subject.on_bittrex?).to be_falsey
    end
  end


end