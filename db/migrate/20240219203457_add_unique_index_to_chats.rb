class AddUniqueIndexToChats < ActiveRecord::Migration[7.1]
  def change
    add_index :chats, [:number, :application_id], unique: true
  end
end
