import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

const String serverAddress = '192.168.1.103';
const int serverPort = 5556;
SharedPreferences? prefs;

class TrainingClient {
  int? userId;
  int? modelId;
  SharedPreferences? prefs;
  void getUserId() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs?.getInt('generatedId');
  }

  TrainingClient() {
    getUserId();
  }

  Future<bool> startTraining(int modelId) async {
    Completer<bool> completer =
        Completer<bool>(); // Completer to handle asynchronous operation

    try {
      final Socket socket = await Socket.connect(serverAddress, serverPort);

      final message = {'message': 'train-start $userId $modelId'};
      final messageJson = json.encode(message);

      socket.write(messageJson);

      socket.listen(
        (List<int> event) {
          final response = utf8.decode(event);
          print('Response from server: $response');
          // Check the response and complete the completer accordingly
          if (response == '1') {
            print('svine');
            completer.complete(true);
          } else {
            completer.complete(false);
          }

          socket.close();
        },
        onError: (error) {
          print('Error: $error');
          completer.complete(false); // Completing with false in case of error
          socket.close();
        },
        onDone: () {
          print('Connection closed by server');
          socket.close();
        },
      );
    } catch (e) {
      print('Exception: $e');
      completer.complete(false); // Completing with false in case of exception
    }

    return completer.future; // Returning the future from the completer
  }

  Future<bool> stopTraining() async {
    Completer<bool> completer =
        Completer<bool>(); // Completer to handle asynchronous operation

    try {
      final Socket socket = await Socket.connect(serverAddress, serverPort);

      final message = {'message': 'train-stop $userId $modelId'};
      final messageJson = json.encode(message);

      socket.write(messageJson);

      socket.listen(
        (List<int> event) {
          final response = utf8.decode(event);
          print('Response from server: $response');

          // Check the response and complete the completer accordingly
          if (response == '1') {
            completer.complete(true);
          } else {
            completer.complete(false);
          }

          socket.close();
        },
        onError: (error) {
          print('Error: $error');
          completer.complete(false); // Completing with false in case of error
          socket.close();
        },
        onDone: () {
          print('Connection closed by server');
          socket.close();
        },
      );
    } catch (e) {
      print('Exception: $e');
      completer.complete(false); // Completing with false in case of exception
    }

    return completer.future;
  }

  Future<double> getProgress() async {
    Completer<double> completer =
        Completer<double>(); // Completer to handle asynchronous operation

    try {
      final Socket socket = await Socket.connect(serverAddress, serverPort);

      final message = {'message': 'train-progress $userId $modelId'};
      final messageJson = json.encode(message);

      socket.write(messageJson);

      socket.listen(
        (List<int> event) {
          final response = utf8.decode(event);
          print('Response from server: $response');

          // Check the response and complete the completer accordingly
          completer.complete(double.parse(response) / 100);

          socket.close();
        },
        onError: (error) {
          print('Error: $error');
          completer.complete(0); // Completing with false in case of error
          socket.close();
        },
        onDone: () {
          print('Connection closed by server');
          socket.close();
        },
      );
    } catch (e) {
      print('Exception: $e');
      completer.complete(0); // Completing with false in case of exception
    }

    return completer.future;
  }
}
