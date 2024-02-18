module Searchable
    extend ActiveSupport::Concern

    included do
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        mappings do
            indexes :body, type: 'text'
            indexes :number, type: 'Numbers'
            indexes :chat_id, type: 'Numbers'
        end

        def self.search(query)
        params = {
            query: {
            multi_match: {
                query: query,
                fields: ['body'],
                fuzziness: "AUTO"
            }
            }
        }

        self.__elasticsearch__.search(params).records.to_a
        end    
    end
end