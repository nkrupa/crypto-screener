require 'open-uri'

module ScreenBuilder

  class Runner
    def self.run!
      puts "Hello World"
      CryptoCompare.data.each do |symbol, data|
        puts "Adding #{symbol}"
        Coin.create! do |c|
          c.symbol = data.fetch("Symbol").downcase
          c.name = data.fetch("FullName")
          c.proof_type = data.fetch("ProofType")
          c.total_supply = data.fetch("TotalCoinSupply")
          c.is_fully_premined = data.fetch("FullyPremined").to_i != 0
          c.cryptocompare_id = data.fetch("Id")
          c.cryptocompare_rank = data.fetch("SortOrder")
        end
      end
    end
  end

  # db model
  
  # symbol
  # name
  # proof_type # cc
  # total_supply # cc
  # is_fully_premined # cc
  # cryptocompare_id
  # cryptocompare_rank

  class CryptoCompare

    # ["Response", "Message", "BaseImageUrl", "BaseLinkUrl", "DefaultWatchlist", "Data", "Type"]
    # ["BTC",
     # {"Id"=>"1182",
     #  "Url"=>"/coins/btc/overview",
     #  "ImageUrl"=>"/media/19633/btc.png",
     #  "Name"=>"BTC",
     #  "Symbol"=>"BTC",
     #  "CoinName"=>"Bitcoin",
     #  "FullName"=>"Bitcoin (BTC)",
     #  "Algorithm"=>"SHA256",
     #  "ProofType"=>"PoW",
     #  "FullyPremined"=>"0",
     #  "TotalCoinSupply"=>"21000000",
     #  "PreMinedValue"=>"N/A",
     #  "TotalCoinsFreeFloat"=>"N/A",
     #  "SortOrder"=>"1",
     #  "Sponsored"=>false}]
    def self.data
      @data ||= JSON.parse(open("https://www.cryptocompare.com/api/data/coinlist/").read).fetch("Data")
    end
  end
end