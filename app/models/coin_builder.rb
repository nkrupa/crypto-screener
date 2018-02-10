require 'open-uri'

module CoinBuilder
  class Runner
    def self.run!
      new.run!
    end
    
    attr_reader :coin_hash

    def initialize
      @coin_hash = {}.with_indifferent_access
    end

    def run!
      load_data

      @coin_hash.each do |symbol, data|
        puts "Adding #{symbol}, data: #{data}"
        Coin.create!(data) do |coin|
          coin.score!
        end
      end
    end

    def load_data
      puts "Loading from CryptoCompare..."
      CryptoCompare.data.each do |symbol, data|
        @coin_hash[symbol] ||= {}
        hash_entry = @coin_hash[symbol]

        hash_entry[:symbol] = symbol
        hash_entry[:name] = data.fetch("FullName")
        hash_entry[:proof_type] = data.fetch("ProofType")
        hash_entry[:is_fully_premined] = data.fetch("FullyPremined").to_i != 0 if data.fetch("FullyPremined") 
        hash_entry[:cryptocompare_id] = data.fetch("Id")
        hash_entry[:cryptocompare_rank] = data.fetch("SortOrder")
        @coin_hash[symbol]
      end
      puts "@coin_hash size #{@coin_hash.size}"

      puts "Loading from CoinMarketCap..."
      CoinMarketCap.data.each do |data|
        symbol = data.fetch("symbol")
        if hash_entry = @coin_hash[symbol]
          hash_entry[:coinmarketcap_id] = data.fetch("id")
          hash_entry[:coinmarketcap_rank] = data.fetch("rank").to_i
          hash_entry[:last_price_btc] = data.fetch("price_btc")
          hash_entry[:market_cap] = data.fetch("market_cap_usd") if data.fetch("market_cap_usd").present?
          hash_entry[:available_supply] = data.fetch("available_supply") if data.fetch("available_supply").present?
          hash_entry[:total_supply] = data.fetch("total_supply") if data.fetch("total_supply").present?
        end
      end

      load_full_data_from_storage.each do |symbol, data|
        if hash_entry = @coin_hash[symbol]
          hash_entry[:last_volume_btc] = data[:btc_volume]
        end
      end

      load_snapshot_data_from_storage.each do |symbol, data|
        if hash_entry = @coin_hash[symbol]
          hash_entry[:exchanges] = data["Data"]["Exchanges"].map{|h| h["MARKET"]} if data["Data"]["Exchanges"]
        end
      end
    end

    def extract_coin_activity
      {}.tap do |hash|
        Coin.positive_fa_score.find_in_batches(batch_size: 50) do |group| 
          symbols = group.map(&:symbol).join(',')
          puts "got symbols: #{symbols}"
          add_coins_to_storage_hash(symbols, hash)
        end
        # loop
         # add hash entry for volume
      end
    end

    # { "RAW" => { "LTC" => "BTC" => {data} } }
    # data: 
    #   {"TYPE"=>"5",
    #    "MARKET"=>"CCCAGG",
    #    "FROMSYMBOL"=>"BOST",
    #    "TOSYMBOL"=>"BTC",
    #    "FLAGS"=>"4",
    #    "PRICE"=>1.76e-06,
    #    "LASTUPDATE"=>1518064906,
    #    "LASTVOLUME"=>1034.93181818,
    #    "LASTVOLUMETO"=>0.001821479999997,
    #    "LASTTRADEID"=>"7429",
    #    "VOLUMEDAY"=>3050.55681818,
    #    "VOLUMEDAYTO"=>0.004401479999997,
    #    "VOLUME24HOUR"=>1034.93181818,
    #    "VOLUME24HOURTO"=>0.001821479999997,
    #    "OPENDAY"=>1.25e-06,
    #    "HIGHDAY"=>1.76e-06,
    #    "LOWDAY"=>1.25e-06,
    #    "OPEN24HOUR"=>1.28e-06,
    #    "HIGH24HOUR"=>1.76e-06,
    #    "LOW24HOUR"=>1.28e-06,
    #    "LASTMARKET"=>"CCEX",
    #    "CHANGE24HOUR"=>4.800000000000001e-07,
    #    "CHANGEPCT24HOUR"=>37.50000000000001,
    #    "CHANGEDAY"=>5.1e-07,
    #    "CHANGEPCTDAY"=>40.8,
    #    "SUPPLY"=>16961292.2854024,
    #    "MKTCAP"=>29.851874422308224,
    #    "TOTALVOLUME24H"=>1034.93181818,
    #    "TOTALVOLUME24HTO"=>0.001821479999997}
    def add_coins_to_storage_hash(symbols, hash)
      data = JSON.parse(open("https://min-api.cryptocompare.com/data/pricemultifull?fsyms=#{symbols}&tsyms=BTC").read)
      data["RAW"].each do |symbol, markets_hash|
        stats = markets_hash["BTC"]
        hash[symbol] = { btc_volume: stats["TOTALVOLUME24HTO"] }
      end
    end

    def add_snapshots_to_storage_hash
      {}.tap do |hash|
        Coin.positive_fa_score.find_in_batches(batch_size: 10) do |group|
          group.each do |coin|
            symbol = coin.symbol
            puts "adding: #{symbol}"
            data = JSON.parse(open("https://www.cryptocompare.com/api/data/coinsnapshot/?fsym=#{symbol}&tsym=BTC").read)
            hash[symbol] = data
          end
          puts "sleeping 5 secs..."
          sleep(5)
        end
      end
    end

    def local_store_snapshot_data!
      hash = add_snapshots_to_storage_hash
      File.open(LOCAL_SNAPSHOT_STORAGE_PATH,'wb'){|f| f.write(hash)}
    end

    LOCAL_VOLUME_STORAGE_PATH = Rails.root.join("data","coin_activity_data.txt")
    LOCAL_SNAPSHOT_STORAGE_PATH = Rails.root.join("data","coin_snapshot_data.txt")

    def local_store_volume_data!
      hash = extract_coin_activity
      File.open(LOCAL_VOLUME_STORAGE_PATH,'wb'){|f| f.write(hash)}
    end

    def load_full_data_from_storage
      eval(File.open(LOCAL_VOLUME_STORAGE_PATH).read).with_indifferent_access
    end

    def load_snapshot_data_from_storage
      eval(File.open(LOCAL_SNAPSHOT_STORAGE_PATH).read).with_indifferent_access
    end

  end

  # TRI criteria
  # 

  # DB - modeling
  #
  # symbol
  # name
  # proof_type # cc
  # total_supply # cc
  # is_fully_premined # cc
  # cryptocompare_id
  # cryptocompare_rank

  # 
  #  {"id"=>"bitcoin",
  # "name"=>"Bitcoin",
  # "symbol"=>"BTC",
  # "rank"=>"1",
  # "price_usd"=>"8296.14",
  # "price_btc"=>"1.0",
  # "24h_volume_usd"=>"9676000000.0",
  # "market_cap_usd"=>"139819717254",
  # "available_supply"=>"16853587.0",
  # "total_supply"=>"16853587.0",
  # "max_supply"=>"21000000.0",
  # "percent_change_1h"=>"-1.03",
  # "percent_change_24h"=>"2.1",
  # "percent_change_7d"=>"-8.52",
  # "last_updated"=>"1518123869"}
  class CoinMarketCap
    def self.data
      @data ||= JSON.parse(open("https://api.coinmarketcap.com/v1/ticker/?limit=0").read)
    end
  end

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


    # {"Response"=>"Success",
     # "Message"=>"This api will soon move to mi-api path.",
     # "Data"=>
      # {"Algorithm"=>nil,
       # "ProofType"=>nil,
       # "BlockNumber"=>0,
       # "NetHashesPerSecond"=>0.0,
       # "TotalCoinsMined"=>16329896.0,
       # "BlockReward"=>0.0,
       # "AggregatedData"=>
        # {"TYPE"=>"5",
         # "MARKET"=>"CCCAGG",
         # "FROMSYMBOL"=>"SIB",
         # "TOSYMBOL"=>"BTC",
         # "FLAGS"=>"4",
         # "PRICE"=>"0.0002426",
         # "LASTUPDATE"=>"1518238643",
         # "LASTVOLUME"=>"198.00462552",
         # "LASTVOLUMETO"=>"0.04811512",
         # "LASTTRADEID"=>"6837787",
         # "VOLUMEDAY"=>"37501.85951836003",
         # "VOLUMEDAYTO"=>"8.921583767289063",
         # "VOLUME24HOUR"=>"91188.75248019001",
         # "VOLUME24HOURTO"=>"21.346147605396464",
         # "OPENDAY"=>"0.0002395",
         # "HIGHDAY"=>"0.000243",
         # "LOWDAY"=>"0.0002326",
         # "OPEN24HOUR"=>"0.0002257",
         # "HIGH24HOUR"=>"0.0002426",
         # "LOW24HOUR"=>"0.000222",
         # "LASTMARKET"=>"BitTrex"},
       # "Exchanges"=>
        # [{"TYPE"=>"2",
          # "MARKET"=>"CCEX",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"4",
          # "PRICE"=>"0.000205",
          # "LASTUPDATE"=>"1518088556",
          # "LASTVOLUME"=>"4.54133562",
          # "LASTVOLUMETO"=>"0.0009309738021",
          # "LASTTRADEID"=>"10083",
          # "VOLUME24HOUR"=>"0",
          # "VOLUME24HOURTO"=>"0",
          # "OPEN24HOUR"=>"0.000205",
          # "HIGH24HOUR"=>"0.000205",
          # "LOW24HOUR"=>"0.000205"},
         # {"TYPE"=>"2",
          # "MARKET"=>"BitTrex",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"2",
          # "PRICE"=>"0.000243",
          # "LASTUPDATE"=>"1518238643",
          # "LASTVOLUME"=>"198.00462552",
          # "LASTVOLUMETO"=>"0.04811512",
          # "LASTTRADEID"=>"6837787",
          # "VOLUME24HOUR"=>"78042.49226867",
          # "VOLUME24HOURTO"=>"18.30822443",
          # "OPEN24HOUR"=>"0.000226",
          # "HIGH24HOUR"=>"0.00024303",
          # "LOW24HOUR"=>"0.00022238"},
         # {"TYPE"=>"2",
          # "MARKET"=>"Cryptopia",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"4",
          # "PRICE"=>"0.000241",
          # "LASTUPDATE"=>"1518228176",
          # "LASTVOLUME"=>"9.82562689",
          # "LASTVOLUMETO"=>"0.00236798",
          # "LASTTRADEID"=>"15182281760001",
          # "VOLUME24HOUR"=>"1602.04619975",
          # "VOLUME24HOURTO"=>"0.37494015",
          # "OPEN24HOUR"=>"0.00022249",
          # "HIGH24HOUR"=>"0.00024673",
          # "LOW24HOUR"=>"0.00022249"},
         # {"TYPE"=>"2",
          # "MARKET"=>"BitSquare",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"4",
          # "PRICE"=>"0.00009524",
          # "LASTUPDATE"=>"1461967161",
          # "LASTVOLUME"=>"1050",
          # "LASTVOLUMETO"=>"0.10000200000000001",
          # "LASTTRADEID"=>"18865",
          # "VOLUME24HOUR"=>"0",
          # "VOLUME24HOURTO"=>"0",
          # "OPEN24HOUR"=>"0.00009524",
          # "HIGH24HOUR"=>"0.00009524",
          # "LOW24HOUR"=>"0.00009524"},
         # {"TYPE"=>"2",
          # "MARKET"=>"LiveCoin",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"4",
          # "PRICE"=>"0.000238",
          # "LASTUPDATE"=>"1518237856",
          # "LASTVOLUME"=>"7.01705095",
          # "LASTVOLUMETO"=>"0.0016700581261",
          # "LASTTRADEID"=>"276054984",
          # "VOLUME24HOUR"=>"11284.764553920002",
          # "VOLUME24HOURTO"=>"2.606306828928371",
          # "OPEN24HOUR"=>"0.00022225",
          # "HIGH24HOUR"=>"0.000238",
          # "LOW24HOUR"=>"0.00021849"},
         # {"TYPE"=>"2",
          # "MARKET"=>"Yobit",
          # "FROMSYMBOL"=>"SIB",
          # "TOSYMBOL"=>"BTC",
          # "FLAGS"=>"4",
          # "PRICE"=>"0.00023779",
          # "LASTUPDATE"=>"1518238051",
          # "LASTVOLUME"=>"10.57739936",
          # "LASTVOLUMETO"=>"0.0025151997938144",
          # "LASTTRADEID"=>"200003009",
          # "VOLUME24HOUR"=>"639.7970969400001",
          # "VOLUME24HOURTO"=>"0.14870118646809038",
          # "OPEN24HOUR"=>"0.00022871",
          # "HIGH24HOUR"=>"0.00023779",
          # "LOW24HOUR"=>"0.00021393"}]},
     # "Type"=>100}
  end
end