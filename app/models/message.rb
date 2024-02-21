class Message < ApplicationRecord
  include Searchable
  
  belongs_to :chat
  validates :body, presence: true, length: {maximum: 4096}
end
