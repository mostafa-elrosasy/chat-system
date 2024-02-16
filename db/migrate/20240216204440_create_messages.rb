class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.integer :number, null:false
      t.references :chat, null: false, foreign_key: true
      t.string :body, limit: 4096, null:false

      t.timestamps
    end
  end
end
