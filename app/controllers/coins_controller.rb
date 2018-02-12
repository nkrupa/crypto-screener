class CoinsController < ApplicationController

  def index
    @container_fluid = true
    @coins = Coin.positive_fa_score.order("tri_fa_score desc, cryptocompare_rank asc").page(params[:page])
  end

  def show
    @coin = Coin.find(params[:id])
  end

  def update
    @coin = Coin.find(params[:id])
    @coin.update_attributes!(coin_params)
    respond_to do |format|
      format.js 
    end
  end

  def watchlist
    @coins ||= Coin.positive_fa_score.order("tri_fa_score desc, cryptocompare_rank")[0..20]
  end

  def coin_params
    params[:coin].permit(:market_structure_status)
  end
end