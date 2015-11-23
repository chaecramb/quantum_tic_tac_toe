class CreateQttMoves < ActiveRecord::Migration
  def change
    create_table :qtt_moves do |t|
      t.integer :square
      t.string :symbol
      t.string :player
      t.integer :partner_id
      t.boolean :collapsed
      t.integer :qtt_id

      t.timestamps null: false
    end
  end
end
