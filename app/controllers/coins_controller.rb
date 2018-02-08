class CoinsController < ApplicationController

  def index
    @coins ||= Coin.order("cryptocompare_rank")
  end
end