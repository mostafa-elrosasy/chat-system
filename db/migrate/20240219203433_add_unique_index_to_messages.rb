class AddUniqueIndexToMessages < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, [:number, :chat_id], unique: true
  end
end
