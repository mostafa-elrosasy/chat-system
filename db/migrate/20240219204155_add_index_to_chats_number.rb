class AddIndexToChatsNumber < ActiveRecord::Migration[7.1]
  def change
    add_index :chats, :number, unique: false
  end
end
