# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180208161747) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coins", force: :cascade do |t|
    t.string "symbol"
    t.string "name"
    t.integer "tri_fa_score"
    t.jsonb "tri_fa_positives", default: []
    t.jsonb "tri_fa_negatives", default: []
    t.string "proof_type"
    t.bigint "available_supply"
    t.bigint "total_supply"
    t.decimal "market_cap"
    t.boolean "is_fully_premined"
    t.integer "cryptocompare_id"
    t.integer "cryptocompare_rank"
    t.string "coinmarketcap_id"
    t.integer "coinmarketcap_rank"
    t.decimal "last_price_btc"
    t.integer "last_volume_btc"
    t.jsonb "exchanges", default: []
    t.string "market_structure_status"
    t.datetime "market_structure_checked_at"
    t.index ["cryptocompare_rank"], name: "index_coins_on_cryptocompare_rank"
    t.index ["exchanges"], name: "index_coins_on_exchanges", using: :gin
    t.index ["symbol"], name: "index_coins_on_symbol"
    t.index ["tri_fa_score"], name: "index_coins_on_tri_fa_score"
  end

end
