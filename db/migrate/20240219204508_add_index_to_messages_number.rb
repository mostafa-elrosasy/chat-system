class AddIndexToMessagesNumber < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, :number, unique: false
  end
end
