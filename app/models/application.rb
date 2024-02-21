class Application < ApplicationRecord
  has_many :chats

  validates :name, presence: true, length: { maximum: 20 }
end
