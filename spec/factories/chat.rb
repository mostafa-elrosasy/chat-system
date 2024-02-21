FactoryBot.define do
  factory :chat do
    sequence(:number) { |n| n }
    messages_count { 0 }
    association :application
  end
end