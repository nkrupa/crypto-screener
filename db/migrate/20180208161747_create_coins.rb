class CreateCoins < ActiveRecord::Migration[5.1]
  def change
    create_table :coins do |t|
      t.string :symbol
      t.string :name
      t.integer :tri_fa_score
      t.jsonb :tri_fa_positives, default: []
      t.jsonb :tri_fa_negatives, default: []
      t.string :proof_type
      t.integer :available_supply, limit: 8
      t.integer :total_supply, limit: 8
      t.decimal :market_cap, limit: 8
      t.boolean :is_fully_premined
      t.integer :cryptocompare_id
      t.integer :cryptocompare_rank
      t.string :coinmarketcap_id
      t.integer :coinmarketcap_rank
      t.decimal :last_price_btc
      t.integer :last_volume_btc
      t.jsonb :exchanges, default: []
      t.string :market_structure_status
      t.timestamp :market_structure_checked_at
    end
    add_index  :coins, :symbol
    add_index  :coins, :tri_fa_score
    add_index  :coins, :cryptocompare_rank
    add_index  :coins, :exchanges, using: :gin

  end
end
