import 'dart:async';
import 'dart:ffi';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';

String host = '192.168.1.104';
int port = 5432;
String username = 'postgres';
String dbName = 'postgres';

class PostgresService {
  Connection? _connection;

  Future<Connection?> getConnection() async {
    Endpoint _endpoint = Endpoint(
      host: host,
      port: port, // Default PostgreSQL port
      database: dbName,
      username: username,
      password: 'timonaki1234',
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      _connection = await Connection.open(_endpoint,
          settings: const ConnectionSettings(sslMode: SslMode.disable));
      print('Connected to local PostgreSQL server');
      return _connection;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> closeConnection() async {
    await _connection?.close();
    print('Connection closed');
  }

  void insert(List<dynamic> parsedJson) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('generatedId');
    int rpm = int.parse(parsedJson[0]['response'].split('.')[0]);
    int speed = int.parse(parsedJson[1]['response'].split('.')[0]);
    int temp = int.parse(parsedJson[2]['response'].split('.')[0]);
    DateTime now = DateTime.now();
    String now_string = now.toString().split('.')[0];

    print(now_string);
    await _connection?.execute(
        Sql.named(
            '''INSERT INTO params ("user_id", "RPM", "Speed", "Temperature", "Datetime")
     VALUES (@id ,@rpm, @speed, @temp, @datetime)'''),
        parameters: {
          'id': id,
          'rpm': rpm,
          'speed': speed,
          'temp': temp,
          'datetime': now_string
        });
  }

  Future<void> addUser(int? id) async {
    bool isAdded = false;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final users =
          await _connection?.execute(Sql.named('''SELECT * FROM users'''));
      for (var user in users!) {
        print(user[0]);
        if (user[0] == id) {
          isAdded = true;
          print('User already added');
        }
      }
      if (!isAdded) {
        await _connection?.execute(Sql.named('''INSERT INTO users ("user_id")
     VALUES (@id)'''), parameters: {'id': id}).timeout(Duration(seconds: 3));
        print('User added');
        return;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> checkConnection() async {
    dynamic isOpen;
    try {
      if (_connection!.isOpen) {
        try {
          isOpen = await _connection!
              .execute(Sql.named('''SELECT test_code FROM test'''))
              .timeout(Duration(seconds: 3));
        } on TimeoutException catch (e) {
          return false;
        }
      }

      if (isOpen?[0][0] == 1) {
        return true;
      } else {
        return false;
      }
      //return isOpen;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
