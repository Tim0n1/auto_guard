import 'dart:ffi';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';

String host = '192.168.1.107';
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
    print('-------------------------------');
    int rpm = int.parse(parsedJson[0]['response'].split('.')[0]);
    int speed = int.parse(parsedJson[1]['response'].split('.')[0]);
    int temp = int.parse(parsedJson[2]['response'].split('.')[0]);
    print('$rpm, $speed, $temp');
    await _connection?.execute(
        Sql.named(
            '''INSERT INTO params ("user_id", "RPM", "Speed", "Temperature")
     VALUES (@id ,@rpm, @speed, @temp)'''),
        parameters: {'id': id, 'rpm': rpm, 'speed': speed, 'temp': temp});
  }

  Future<void> addUser(int? id) async {
    try {
      await _connection?.execute(Sql.named('''INSERT INTO users ("user_id")
     VALUES (@id)'''), parameters: {'id': id});
    } catch (e) {
      print(e);
    }
  }

  Future<bool> checkConnection() async {
    try {
      if (_connection?.isOpen == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }
}
