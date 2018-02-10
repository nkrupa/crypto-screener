class Coin < ApplicationRecord
  validates :symbol, presence: true, uniqueness: true

  # serialize :exchanges, Array

  scope :positive_fa_score, -> { where("tri_fa_score >= 1")}

  # scope :tri_fa_prime, -> do
  #   where("available_supply IS NOT NULL AND available_supply BETWEEN ? AND ?", 1_000, 25_000_000).
  #   where("market_cap > ?", 5_000_000)#.
  #   # where("last_volume_btc BETWEEN ? AND ?", 10, 100)
  # end

  def self.for(symbol)
    find_by!(symbol: symbol.upcase) 
  end

  def on_cryptopia?
    self.exchanges.any? && self.exchanges.include?("Cryptopia")
  end

  def on_bittrex?
     self.exchanges.any? && self.exchanges.include?("BitTrex")
  end

  def on_binance?
     self.exchanges.any? && self.exchanges.include?("Binance")
  end

  def chartable?
    on_bittrex?
  end

  def coinigy_url
    "https://www.coinigy.com/main/markets/#{coinigy_exchange}/#{self.symbol}/BTC"
  end

  def coinigy_exchange
    if on_bittrex?
      "BTRX"
    elsif on_cryptopia?
      "CPIA"
    elsif on_binance?
      "BINA"
    end
  end

  def score!
    self.tri_fa_score = 0

    # POSITIVES
    if self.available_supply.to_i > 1_000 and self.available_supply.to_i < 25_000_000
      self.tri_fa_score += 1
      self.tri_fa_positives << 'Coin supply < 25 million'
    end      

    if self.market_cap.to_i < 5_000_000
      self.tri_fa_score += 1
      self.tri_fa_positives << 'market cap < 5 million'
    end      

    if self.last_volume_btc.to_i > 10 and self.last_volume_btc.to_i < 30
      self.tri_fa_score += 1
      self.tri_fa_positives << 'BTC volume < 30'
    end      

    if self.proof_type.to_s.downcase == 'pow'
      self.tri_fa_score += 1
      self.tri_fa_positives << 'Proof of Work'
    end

    if self.exchanges.size > 1
      self.tri_fa_score += 1
      self.tri_fa_positives << 'Multiple Exchanges'
    end

    # NEGATIVES
    if is_fully_premined?
      self.tri_fa_score -= 1
      self.tri_fa_negatives << 'Pre Mined'
    end

    if self.exchanges.size <= 1
      self.tri_fa_score -= 1
      self.tri_fa_negatives << '1 or 0 exchange'
    end
  end

  def tooltip_score_summary
    [].tap do |summary|
      if self.tri_fa_positives.any?
        summary << "POSITIVES:"
        summary.concat(self.tri_fa_positives)
      end
      if self.tri_fa_negatives.any?
        summary << "NEGATIVES:"
        summary.concat(self.tri_fa_negatives)
      end
    end
  end
end
