class Message < ApplicationRecord
  include Searchable

  belongs_to :chat
end
