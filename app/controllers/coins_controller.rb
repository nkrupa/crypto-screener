class CoinsController < ApplicationController

  def index
    @coins = Coin.positive_fa_score.order("tri_fa_score desc, cryptocompare_rank asc").page(params[:page])
  end

  def watchlist
    @coins ||= Coin.positive_fa_score.order("tri_fa_score desc, cryptocompare_rank")[0..20]
  end
end