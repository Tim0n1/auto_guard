import 'dart:async';
import 'dart:ffi';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';

String host = '192.248.169.154';
int port = 5432;
String username = 'postgres';
String dbName = 'postgres';

class PostgresService {
  final int? id;
  PostgresService({this.id});

  Connection? _connection;

  Future<Connection?> getConnection() async {
    Endpoint _endpoint = Endpoint(
      host: host,
      port: port, // Default PostgreSQL port
      database: dbName,
      username: username,
      password: 'timonaki1234',
    );

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

  void insert(List<dynamic> parsedJson, int? modelId) async {
    if (_connection == null) {
      print('Cannot insert data. Connection is null');
      return;
    }
    if (modelId == null) {
      print('Cannot insert data. Model id is null');
      return;
    }

    int modelSize = await getModelSize(modelId);
    int modelMaxSize = await getModelMaxSize(modelId);
      int? voltage;
      int? rpm;
      int? speed;
      int? temp;
      int? manifoldPressure;
      try{
      for (var i = 0; i < parsedJson.length; i++) {
        if (parsedJson[i]['title'] == 'Напрежение на акумулатора') {
          //voltage = int.parse(parsedJson[i]['response'].split('.')[0]);
        } else if (parsedJson[i]['title'] == 'Обороти') {
          rpm = int.parse(parsedJson[i]['response'].split('.')[0]);
        } else if (parsedJson[i]['title'] == 'Скорост на автомобила') {
          speed = int.parse(parsedJson[i]['response'].split('.')[0]);
        } else if (parsedJson[i]['title'] == 'Температура на двигателя') {
          temp = int.parse(parsedJson[i]['response'].split('.')[0]);
        } else if (parsedJson[i]['title'] == 'Абсолютно налягане в колектора') {
          manifoldPressure = int.parse(parsedJson[i]['response'].split('.')[0]);
        }
      }
    } catch (e) {
      print(e);
    }
    if (rpm == null || speed == null || temp == null) {
      return;
    }

    DateTime now = DateTime.now();
    String now_string = now.toString().split('.')[0];

    await _connection?.execute(
        Sql.named(
            '''INSERT INTO params ("user_id","model_id","RPM", "Speed", "Temperature", "datetime")
     VALUES (@id,@model_id ,@rpm, @speed, @temp, @datetime)'''),
        parameters: {
          'id': id,
          'rpm': rpm,
          'speed': speed,
          'temp': temp,
          'datetime': now_string,
          'model_id': modelId,
        });

    if (modelSize == modelMaxSize) {
    print('data is successfully inserted');
    } else {
      await setModelSize(modelId, modelSize + 1);
    }
  }

  Future<void> addUser() async {
    bool isAdded = false;
    try {
      final users =
          await _connection?.execute(Sql.named('''SELECT * FROM users'''));
      for (var user in users!) {
        print(user[0]);
        print(id);
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

  Future<dynamic> getModels() async {
    if (_connection != null) {
      try {
        final models = await _connection?.execute(
            Sql.named('''SELECT * FROM models WHERE user_id = @id'''),
            parameters: {'id': id}).timeout(Duration(milliseconds: 2100));
        if (models?.isEmpty != true) {
          return models;
        } else {
          return [];
        }
      } on TimeoutException catch (e) {
        print(e);
        print('istinsko problemche');
        return ['r'];
      }
    } else {
      print('Connection is null');
      return [];
    }
  }

  Future<void> addModel(String name, int size, maxSize) async {
    bool isAdded = false;
    try {
      final models = await _connection
          ?.execute(Sql.named('''SELECT name FROM models'''))
          .timeout(Duration(seconds: 3));
      for (var m in models!) {
        if (m[0] == name) {
          isAdded = true;
          print('Model already added');
        }
      }
      if (!isAdded) {
        await _connection?.execute(
            Sql.named(
                '''INSERT INTO models ("user_id", "name", "size", "max_size", "is_Trained")
     VALUES (@id, @name, @size, @max_size, @is_Trained)'''),
            parameters: {
              'id': id,
              'name': name,
              'size': size,
              'max_size': maxSize,
              'is_Trained': false,
            }).timeout(Duration(seconds: 3));
        print('Model added');
        return;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> setModelMaxSize(int modelId, int size) async {
    //todo needs fix
    try {
      await _connection?.execute(
          Sql.named(
              '''UPDATE models SET max_size = @size WHERE model_id = @model_id AND user_id = @id'''),
          parameters: {
            'model_id': modelId,
            'size': size,
            'id': id,
          }).timeout(Duration(seconds: 3));
      return;
    } catch (e) {
      print(e);
    }
  }

  Future<void> setModelSize(int modelId, int size) async {
    try {
      await _connection?.execute(
          Sql.named(
              '''UPDATE models SET size = @size WHERE model_id = @model_id AND user_id = @id'''),
          parameters: {
            'size': size,
            'model_id': modelId,
            'id': id,
          }).timeout(Duration(seconds: 3));

      return;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getModelMaxSize(int modelId) async {
    try {
      final size = await _connection?.execute(
          Sql.named(
              '''SELECT max_size FROM models WHERE model_id = @model_id AND user_id = @id'''),
          parameters: {
            'model_id': modelId,
            'id': id,
          }).timeout(Duration(seconds: 3));
      return size?[0][0];
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getModelSize(int modelId) async {
    try {
      final size = await _connection?.execute(
          Sql.named(
              '''SELECT size FROM models WHERE model_id = @model_id AND user_id = @id'''),
          parameters: {
            'model_id': modelId,
            'id': id,
          }).timeout(Duration(seconds: 3));
      print('Model size get $size');
      return size?[0][0];
    } catch (e) {
      print(e);
    }
  }

  Future<bool> deleteModel(String name) async {
    try {
      await _connection?.execute(
          Sql.named(
              '''DELETE FROM models WHERE user_id = @id AND name = @name'''),
          parameters: {'id': id, 'name': name}).timeout(Duration(seconds: 3));
      print('Model deleted');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> addFault(
      int modelId, double score, int? rpm, int? speed, int? temp,
      {int? anomaly_rpm, int? anomaly_speed, int? anomaly_temp}) async {
    try {
      DateTime now = DateTime.now();
      String now_string = now.toString().split('.')[0];

      final sample_id = await _connection?.execute(
          Sql.named(
              '''INSERT INTO params ("user_id","model_id","RPM", "Speed", "Temperature", "datetime")
     VALUES (@id,@model_id ,@rpm, @speed, @temp, @datetime) RETURNING "info_id"'''),
          parameters: {
            'id': id,
            'rpm': rpm,
            'speed': speed,
            'temp': temp,
            'datetime': now_string,
            'model_id': modelId,
          });

      await _connection?.execute(
          Sql.named(
              '''INSERT INTO faults ("user_id","model_id","sample_id","anomaly_rpm", "anomaly_speed", "anomaly_temperature","anomaly", "datetime")
     VALUES (@id,@model_id, @sample_id ,@anomaly_rpm, @anomaly_speed, @anomaly_temp, @score, @datetime)'''),
          parameters: {
            'id': id,
            'sample_id': sample_id?[0][0],
            'anomaly_rpm': anomaly_rpm,
            'anomaly_speed': anomaly_speed,
            'anomaly_temp': anomaly_temp,
            'datetime': now_string,
            'score': score,
            'model_id': modelId,
          });
      print('fault added');
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> getFaults() async {
    if (_connection != null) {
      final faults = await _connection?.execute(
          Sql.named(
              '''SELECT faults.fault_id,faults.user_id,models.name,faults.sample_id,faults.anomaly_rpm, faults.anomaly_speed, faults.anomaly_temperature, faults.anomaly, faults.datetime AS models_name FROM faults LEFT JOIN 
                  models ON models.model_id = faults.model_id WHERE faults.user_id = @user_id'''),
          parameters: {'user_id': id}).timeout(Duration(seconds: 3));
      return faults;
    } else {
      print('Connection is null!');
      return [];
    }
  }
}
