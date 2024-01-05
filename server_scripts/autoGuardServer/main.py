import database

server = database.PostgresServer()
server.connect()

data = server.get_data(163666, 20)
print(data)