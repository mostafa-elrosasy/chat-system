# General Instructions

* To run the system:
```bash
git clone https://github.com/mostafa-elrosasy/chat-system.git
cd chat-system
docker compose up
```

* If you face error: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144], from elasticsearch run in the ubuntu terminal:

```bash
sudo sysctl -w vm.max_map_count=262144
```

* After the db service finish setting up the database and user run:
```bash
docker exec app rake db:migrate
```

* To run the tests.
```bash
docker exec app rspec
```

* You can change the following lines in "config/application.rb" to control the batch size for the chats and messages creation.
```
config.chats_batch_size = 3
config.messages_batch_size = 3
```
The chats and messages won't be created until their respective queues have at least batch size items. The batch is currently 3 to make testing the system easier.


The system is listening on localhost:3000.

Please use this collection to interact with the system, it contains all the endpoints and examples on how to use them
https://www.postman.com/mostafa-elrosasy/workspace/mostafa-elrosasy/collection/6616350-c5da9022-0c63-4e6b-9d27-f231a2c47d80?action=share&creator=6616350

