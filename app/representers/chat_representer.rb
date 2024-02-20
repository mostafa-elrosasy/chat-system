class ChatRepresenter
    def initialize chats
        @chats = chats
    end

    def as_json
        return serialize chats unless chats.respond_to?(:each)
        
        chats.map(&method(:serialize))
    end

    def serialize message
        {
            "number": message.number,
            "messages_count": message.messages_count,
        }
    end

    private

    attr_reader :chats
end