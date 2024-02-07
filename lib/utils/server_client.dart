import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

const String serverAddress = '192.168.1.104';
const int serverPort = 5556;
SharedPreferences? prefs;

class TrainingClient {
  int? userId;
  void getUserId() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs?.getInt('generatedId');
  }

  TrainingClient() {
    getUserId();
  }

  Future<void> startTraining(int modelId) async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs?.getInt('generatedId');
    // Connect to the server
    final socket = await Socket.connect(serverAddress, serverPort);

    // Define the message to send
    final message = {'message': 'train-start $userId $modelId'};

    // Convert the message to JSON format
    final messageJson = json.encode(message);

    // Send the message to the server
    socket.write(messageJson);

    // Listen for response from the server
    socket.listen(
      (List<int> event) {
        final response = utf8.decode(event);
        print('Response from server: $response');
        socket.close(); // Close the socket after receiving the response
      },
      onError: (error) {
        print('Error: $error');
        socket.close(); // Close the socket in case of an error
      },
      onDone: () {
        print('Connection closed by server');
        socket
            .close(); // Close the socket when the connection is closed by the server
      },
    );
  }
}
