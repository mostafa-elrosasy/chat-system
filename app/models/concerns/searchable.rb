module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    mappings do
      indexes :body, type: 'text'
      indexes :chat_id, type: 'keyword'
    end

    def self.search(message_body, chat_id, page_number, size)
      from = (page_number - 1) * size
      params = {
        from: from,
        size: size,
        query: {
          bool: {
            must: [
              {
                multi_match: {
                  query: message_body,
                  fields: ['body'],
                  fuzziness: 'AUTO'
                }
              },
              {
                term: {
                  chat_id: chat_id
                }
              }
            ]
          }
        }
      }

      __elasticsearch__.search(params).records.to_a
    end
  end
end
