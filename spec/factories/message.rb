# spec/factories/messages.rb

FactoryBot.define do
    factory :message do
      sequence(:number) { |n| n }
      association :chat
  
      body { 'Hello' }
    end
end
  