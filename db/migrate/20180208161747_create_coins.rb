class CreateCoins < ActiveRecord::Migration[5.1]
  def change
    create_table :coins do |t|
      t.string :symbol
      t.string :name
      t.string :proof_type
      t.integer :total_supply, limit: 8
      t.boolean :is_fully_premined
      t.integer :cryptocompare_id
      t.integer :cryptocompare_rank
    end
  end
end
