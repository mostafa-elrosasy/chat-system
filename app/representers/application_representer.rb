class ApplicationRepresenter
    def initialize application
        @application = application
    end
    
    def as_json
        {
            "token": @application.token,
            "name": @application.name,
            "chats_count": @application.chats_count,
        }   
    end
end