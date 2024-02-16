class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.string :token, limit: 36, null:false
      t.string :name, limit: 20, null:false
      t.integer :chats_count, null:false

      t.timestamps
    end
  end
end
