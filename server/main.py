import database
import json
import socket
import operation_manager
import threading
import traceback
from path import Path
import sys
import asyncio
# directory reach
directory = Path(__file__).abspath()
# setting path
sys.path.append(directory.parent.parent)


SERVER_ADDRESS = '192.168.1.104'
SERVER_PORT = 5556
id = 69066
columns = ["RPM", "Speed", "Temp"]
# server = database.PostgresServer()
# server.connect()
operations = operation_manager.Operations()



async def handle_client_connection(conn, addr):
    progress = None
    loop = asyncio.get_running_loop()
    while True:
        try:
            data = await loop.sock_recv(conn, 1024)
            data = data.decode()
        except ConnectionResetError:
            break

        if not data:
            break

        try:
            response = 0
            print(data)
            message = json.loads(data)
            input1 = message['message'].split(' ')
            user_id = input1[1]
            model_id = input1[2]
            command = input1[0]
            print(f'Received message: {input1}')

            if command == 'train-start':
                operations.progress = 0
                asyncio.create_task(operations.start_training(user_id, model_id))
                response = 1
            elif command == 'train-stop':
                success = await operations.stop_training(user_id, model_id)
                response = 1 if success else 0
            elif command == 'train-progress':
                success, progress = await operations.get_progress(user_id, model_id)
                response = progress if success else 0
            elif command == 'inference':
                sample = message['data']
                response = await operations.predict(user_id, model_id, sample)
                response = response.tolist()[0]
                print(response)
                
            else:
                response = "Invalid command"

            response_json = json.dumps(response)
            await loop.sock_sendall(conn, response_json.encode())
        except Exception as e:
            print(traceback.format_exc())

    conn.close()

async def main(SERVER_ADDRESS, SERVER_PORT):
    loop = asyncio.get_running_loop()
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((SERVER_ADDRESS, SERVER_PORT))
        s.listen()
        print('Server is running...')

        while True:
            conn, addr = await loop.sock_accept(s)
            print(f'Client connected: {addr}')

            await handle_client_connection(conn, addr)

asyncio.run(main(SERVER_ADDRESS, SERVER_PORT))
