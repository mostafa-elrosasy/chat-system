class AddIndexToApplicationsToken < ActiveRecord::Migration[7.1]
  def change
    add_index :applications, :token, unique: true
  end
end
