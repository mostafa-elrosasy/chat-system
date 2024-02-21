FactoryBot.define do
  factory :application do
    name { 'Test Application' }
    token { SecureRandom.uuid }
    chats_count { 0 }
  end
end
