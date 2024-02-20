class ChatRepresenter
    def initialize chats
        @chats = chats
    end

    def as_json
        return serialize chats unless chats.respond_to?(:each)
        
        chats.map(&method(:serialize))
    end

    def serialize chat
        {
            "number": chat.number,
            "messages_count": chat.messages_count,
        }
    end

    private

    attr_reader :chats
end