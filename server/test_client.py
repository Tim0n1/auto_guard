import socket
import json

SERVER_ADDRESS = '192.168.1.100'
SERVER_PORT = 5556

async def send_message(command, user_id, model_id):
    message = json.dumps({'message': f"{command} {user_id} {model_id}"})
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((SERVER_ADDRESS, SERVER_PORT))
            s.sendall(message.encode())

            response = s.recv(1024)
            return response.decode()
    except ConnectionRefusedError:
        return "Connection refused by the server."
    except Exception as e:
        return f"An error occurred: {e}"

async def main():
    user_id = 244312  # Your user ID
    model_id = 176  # Your model ID

    command = input("Enter command (train-start, train-stop, train-progress): ")

    if command in ['train-start', 'train-stop', 'train-progress']:
        response = await send_message(command, user_id, model_id)
        print("Response from server:", response)
    else:
        print("Invalid command.")

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
