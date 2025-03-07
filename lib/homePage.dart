import 'dart:convert';
import 'package:vin_decoder/vin_decoder.dart';
import 'package:flatur/inferencePage.dart';
import 'package:flatur/liveDataPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:obd2_plugin/obd2_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flatur/trainingPage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:ui';
import 'settingsScreen.dart';
import 'obd2.dart';
import 'package:postgres/postgres.dart';
import 'DB.dart';
import 'utils/blinkingIcon.dart';
import 'utils/findImage.dart';
import 'utils/trainingPopUpMenu.dart';
import 'utils/server_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.controller1, this.controller2});
  @override
  _HomeState createState() => _HomeState();
  final StreamController? controller1;
  final StreamController? controller2;
}

class _HomeState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Callback functions for training page
  void _enableInsertionCallback(bool isEnabled, int modelId) {
    _isDBinsertionEnabled = isEnabled;
    _modelId = modelId;
  }

  void _isTrainingCallback(bool isTraining, int modelId) {
    _isTraining = isTraining;
    _modelId = modelId;
  }

  bool _isInternetEnabled = false;
  int? _modelId;
  List<dynamic> InferenceModel = [];

  int? _modelIdCallback() {
    return _modelId;
  }

  Map<String, bool> _connectionsStateCallback() {
    return {
      'isInternetEnabled': _isInternetEnabled,
      'isDatabaseEnabled': _isDatabaseConnected,
      'isDeviceCompatible': _isDeviceCompatible,
      'isDBinsertionEnabled': _isDBinsertionEnabled,
      'isTraining': _isTraining
    };
  }

  String currentVersion = 'v0.1';

  int? id;

  bool _isDatabaseConnected = false;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _connectedDevice;
  bool _bluetoothPermissionGranted = false;
  bool _notificationsPermissionsGranted = false;

  PostgresService postgresService = PostgresService();
  TrainingClient trainingClient = TrainingClient();

  bool _serviceRunning = true;
  bool _isDeviceCompatible = false;
  bool _isDeviceCompatibleButtonEnabled = true;
  bool _isDBinsertionEnabled = false;
  bool _isTraining = false;
  bool _isInferencing = false;

  Map<String, String?> carInformation = {
    "manufacturer": 'Toyota',
    "model": null
  };
  String? carManufacturerLogo = '';
  String vinNumber = '';
  Obd2Plugin obd2 = Obd2Plugin();

  String currentState = '';

  //Stream<void>? _stream;
  //StreamController _eventController1 = StreamController.broadcast();

  late Timer _deviceRefreshTimer;
  static const int _refreshInterval = 3; // Refresh interval in seconds

  int _currentIndex = 0;

  Timer? _timer;

  bool isConnected = false; // New variable to track connection status

  @override
  void initState() {
    super.initState();
    _setId();
    _initInternetConnection();
    _checkDBconnection();
    _initBluetooth();
    _startDeviceRefreshTimer();
    startParamsExtraction();
    checkObdCompatibility();
  }

  @override
  void dispose() {
    _deviceRefreshTimer.cancel();
    //_subscription?.cancel();
    super.dispose();
  }

  void _setId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? newId = prefs.getInt('generatedId');
    id = newId;
    postgresService = PostgresService(id: id);
    print(id);
  }

  Future<int?> inserUserId() async {
    postgresService.addUser();
    return id;
  }

  Future<double> inference(List<dynamic> sample) async {
    prefs = await SharedPreferences.getInstance();
    int? threshold = prefs?.getInt('threshold');
    List<dynamic> anomalyScores = [];
    double anomalyScore;
    int? voltage;
    int? rpm;
    int? speed;
    int? temp;
    int? manifoldPressure;
    for (var i = 0; i < sample.length; i++) {
      if (sample[i]['response'] == null) {
        return 0;
      }
    }
    for (var i = 0; i < sample.length; i++) {
      if (sample[i]['title'] == 'Напрежение на акумулатора') {
        //voltage = int.parse(parsedJson[i]['response'].split('.')[0]);
      } else if (sample[i]['title'] == 'Обороти') {
        rpm = int.parse(sample[i]['response'].split('.')[0]);
      } else if (sample[i]['title'] == 'Скорост на автомобила') {
        speed = int.parse(sample[i]['response'].split('.')[0]);
      } else if (sample[i]['title'] == 'Температура на двигателя') {
        temp = int.parse(sample[i]['response'].split('.')[0]);
      } else if (sample[i]['title'] == 'Абсолютно налягане в колектора') {
        manifoldPressure = int.parse(sample[i]['response'].split('.')[0]);
      }
    }
    anomalyScore =
        await trainingClient.inference([rpm, speed, temp], InferenceModel[0]);

    if (threshold != null) {
      print(threshold);
      if (anomalyScore > threshold) {
        await postgresService.addFault(
            InferenceModel[0], anomalyScore, rpm, speed, temp);
      }
    }

    return anomalyScore;
  }

  Future<void> startParamsExtraction() async {
    StreamController _eventController1 = widget.controller1!;
    StreamController _eventController2 = widget.controller2!;
    List<List<dynamic>> insertionList = [];
    List<String> timeList = [];
    int tempUpdate = 0;
    int modelSize;
    int maxSize;

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!_serviceRunning) {
        print("service not running");
        return;
      }

      DartPluginRegistrant.ensureInitialized();

      if (_connectedDevice != null) {
        if (!await obd2.hasConnection) {
          obd2.getConnection(
              _connectedDevice!, (connection) => null, (message) => null);
        } else {
          await Future.delayed(Duration(
              milliseconds: await obd2.configObdWithJSON(StringJson().config)));

          print('obd has connection');
          if (!(await obd2.isListenToDataInitialed)) {
            obd2.setOnDataReceived((command, response, requestCode) async {
              try {
                List<dynamic> parsedJson = [];
                if (!_eventController1.isClosed) {
                  if (_isInferencing) {
                    List<dynamic> anomalyScores;
                    double anomalyScore = 0;
                    parsedJson = json.decode(response);
                    anomalyScore = await inference(
                        parsedJson.sublist(0, parsedJson.length - 1));
                    _eventController2.add([1, anomalyScore]);
                  } else {
                    _eventController2.add([0]);
                  }
                  _eventController1.add(response);
                } else {
                  print("startirame");
                  _eventController1 = StreamController.broadcast();
                }
                if (!_isInferencing) {
                  parsedJson = json.decode(response);
                }
                vinNumber = parsedJson[parsedJson.length - 1]['response'];
                if (_isDBinsertionEnabled) {
                  DateTime now = DateTime.now();
                  String now_string = now.toString().split('.')[0];
                  timeList.add(now_string);
                  insertionList
                      .add(parsedJson.sublist(0, parsedJson.length - 1));
                  if (_isDatabaseConnected != false && _isDBinsertionEnabled) {
                    maxSize = await postgresService.getModelMaxSize(_modelId!);
                    modelSize = await postgresService.getModelSize(_modelId!);
                    if (modelSize == maxSize) {
                      print('data is successfully inserted');
                    } else {
                      await postgresService.setModelSize(
                          _modelId!, modelSize + 1);
                    }
                  } else {
                    tempUpdate += 1;
                  }
                  if (insertionList.length >= 8) {
                    if (_isDatabaseConnected != false) {
                      if (_isDBinsertionEnabled) {
                        print('inserting');
                        try {
                          postgresService.insert(
                              insertionList, timeList, _modelId);
                          insertionList = [];
                          timeList = [];
                          if (tempUpdate != 0) {
                            modelSize =
                                await postgresService.getModelSize(_modelId!);
                            await postgresService.setModelSize(
                                _modelId!, modelSize + tempUpdate);
                            tempUpdate = 0;
                          }
                        } catch (e) {
                          print('insert problem $e');
                        }
                      }
                    }
                  } else {
                    print('no DB connection');
                  }
                }
              } catch (e) {
                print(e);
              }
            });
          }
          while (await obd2.hasConnection && _connectedDevice != null) {
            String params = await StringJson().getChosenParams();
            try {
              await Future.delayed(
                  Duration(milliseconds: await obd2.getParamsFromJSON(params)));
            } catch (e) {
              print(e);
            }
          }
        }
      } else {
        print('no connected device');
      }
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothAdvertise.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.location.request().isGranted) {
      return true;
    } else {
      return false;
    }
  }

  void _initInternetConnection() async {
    InternetConnectionChecker().onStatusChange.listen((status) {
      setState(() {
        _isInternetEnabled = status == InternetConnectionStatus.connected;
      });
      if (!_isInternetEnabled) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No Internet Connection'),
            content: const Text('Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _checkDBconnection() async {
    bool dbConnection = false;
    bool isUserAdded = false;
    try {
      while (true) {
        await Future.delayed(Duration(seconds: 2));
        print('checking DB connection');
        try {
          if (await InternetConnectionChecker().hasConnection) {
            try {
              dbConnection = await postgresService.checkConnection();
              //print('$dbConnection 1111');
            } catch (e) {
              print(e);
            }
            if (dbConnection == true) {
              if (!isUserAdded) {
                int? id = await inserUserId();
                isUserAdded = true;
              }

              setState(() {
                _isDatabaseConnected = dbConnection;
              });
            } else {
              if (await InternetConnectionChecker().hasConnection) {
                Connection? _conn = await postgresService.getConnection();
                dbConnection = await postgresService.checkConnection();
                setState(() {
                  _isDatabaseConnected = dbConnection;
                });
              }
            }
          } else {
            setState(() {
              _isDatabaseConnected = false;
            });
          }
        } catch (e) {
          print(e);
          _isDatabaseConnected = false;
        }
      }
    } catch (e) {
      print(e);
      _isDatabaseConnected = false;
    }
  }

  Future<void> _checkBluetoothPermission() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool permissionGranted =
        prefs.getBool('bluetoothPermissionGranted') ?? false;

    if (!permissionGranted) {
      // If permission not granted previously, request it now
      bool newPermissionGranted = await checkAndRequestPermissions();
      if (newPermissionGranted) {
        setState(() {
          _bluetoothPermissionGranted = true;
        });
        // Save the permission status in SharedPreferences
        await prefs.setBool('bluetoothPermissionGranted', true);
      }
    } else {
      setState(() {
        _bluetoothPermissionGranted = true;
      });
    }
  }

  Future<void> _checkNotificationsPermission() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool permissionGranted =
        prefs.getBool('notificationsPermissionGranted') ?? false;

    if (!permissionGranted) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      bool? newPermissionGranted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      if (newPermissionGranted!) {
        setState(() {
          _notificationsPermissionsGranted = true;
        });
        await prefs.setBool('notificationsPermissionGranted', true);
      }
    } else {
      setState(() {
        _notificationsPermissionsGranted = true;
      });
    }
  }

  Future<void> _initBluetooth() async {
    await _checkBluetoothPermission();
    await _checkNotificationsPermission();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    await _updateConnectedDevice();
  }

  Future<void> _updateConnectedDevice() async {
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    for (var i = 0; i < devices.length; i++) {
      if (devices[i].isConnected) {
        setState(() {
          _connectedDevice = devices[i];
          isConnected = true; // Update connection status
        });
        return;
      }
    }
    setState(() {
      _connectedDevice = null;
      isConnected = false; // Update connection status
    });
  }

  void _startDeviceRefreshTimer() {
    _deviceRefreshTimer =
        Timer.periodic(const Duration(seconds: _refreshInterval), (timer) {
      if (_bluetoothPermissionGranted && _notificationsPermissionsGranted) {
        _updateConnectedDevice();
      } // Update connected device status
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              padding:
                  const EdgeInsets.only(top: 0), // Adjust top padding as needed
              child: Image.asset(
                'lib/images/logoto.png', // Replace with your logo asset path
                width: 280, // Adjust width as needed
                height: 220, // Adjust height as needed
              ),
            ),
          ),
          Positioned(
              top: 220,
              left: 0,
              right: 0,
              child: Container(
                child: _isDeviceCompatible && carManufacturerLogo != null
                    ? Image.asset(
                        carManufacturerLogo!,
                        width: 110, // Adjust width as needed
                        height: 110, // Adjust height as needed)
                      )
                    : BlinkingIcon(_isDeviceCompatible),
              )),
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrainingPage(
                                  postgresService: postgresService,
                                  statesCallback: _connectionsStateCallback,
                                  serviceCallback: _enableInsertionCallback,
                                  modelCallback: _modelIdCallback,
                                  trainingCallback: _isTrainingCallback,
                                )));
                  },
                  icon: Icon(Icons.fitness_center),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 60), // Adjust padding
                    textStyle:
                        const TextStyle(fontSize: 20), // Adjust text size
                    minimumSize:
                        const Size(240, 80), // Adjust minimum button size
                  ),
                  label: const Text('Training mode'),
                ),
                const SizedBox(height: 24), // Add spacing between buttons
                ElevatedButton.icon(
                  onPressed: _connectedDevice != null
                      ? () {
                          setState(() {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return TrainableModels(
                                    postgresService: postgresService,
                                    onItemSelected:
                                        (List<dynamic> selectedItem) {
                                      setState(() {
                                        InferenceModel = selectedItem;
                                        if (InferenceModel.isNotEmpty) {
                                          _isInferencing = true;
                                        } else {
                                          _isInferencing = false;
                                        }
                                        print(InferenceModel);
                                      });
                                    },
                                    model: InferenceModel,
                                    isInferencing: _isInferencing,
                                  );
                                });
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 60), // Adjust padding
                    textStyle:
                        const TextStyle(fontSize: 20), // Adjust text size
                    minimumSize:
                        const Size(240, 80), // Adjust minimum button size
                  ),
                  icon: Icon(Icons.health_and_safety),
                  label: const Text('Inference mode'),
                ),
                const SizedBox(height: 10), // Add spacing between buttons
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              //color: Colors.white.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _bluetoothState == BluetoothState.STATE_ON
                        ? 'Bluetooth ON'
                        : 'Bluetooth OFF',
                    style: TextStyle(
                      color: _bluetoothState == BluetoothState.STATE_ON
                          ? Colors.green
                          : Colors.black,
                    ),
                  ),
                  //const SizedBox(height: 8), // Add spacing between texts
                  Text(
                    isConnected
                        ? 'Connected Device:\n ${_connectedDevice?.name}'
                        : 'Not connected',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Text(
                  //   _connectedDevice?.name ?? 'Not connected',
                  //   style: TextStyle(
                  //     color: isConnected ? Colors.green : Colors.black,
                  //   ),
                  // ),
                  Row(
                    children: [
                      Visibility(
                        visible: _isInternetEnabled,
                        child: Icon(
                          Icons.wifi,
                          color: Colors.green,
                        ),
                      ),
                      Visibility(
                        visible: !_isInternetEnabled,
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (_, double value, __) {
                            return Opacity(
                              opacity: value,
                              child: Icon(
                                Icons.wifi,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: _isDatabaseConnected,
                        child: Icon(
                          Icons.satellite_alt,
                          color: Colors.green,
                        ),
                      ),
                      Visibility(
                        visible: !_isDatabaseConnected,
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (_, double value, __) {
                            return Opacity(
                              opacity: value,
                              child: Icon(
                                Icons.satellite_alt,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                      Visibility(
                        visible: _isDeviceCompatible,
                        child: Icon(
                          Icons.car_repair,
                          color: Colors.green,
                        ),
                      ),
                      Visibility(
                        visible: !_isDeviceCompatible,
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (_, double value, __) {
                            return Opacity(
                              opacity: value,
                              child: Icon(
                                Icons.car_repair,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0, right: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    !_isDeviceCompatible
                        ? "Device is not\n compatible"
                        : carInformation['manufacturer'] == null
                            ? 'Check OBD\n compatibility'
                            : "${carInformation['manufacturer']} ${carInformation['model'] ?? ''}",
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      // Add any other text styles as needed
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void checkObdCompatibility() async {
    while (true) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _isDeviceCompatibleButtonEnabled = false;
        });
        if (vinNumber.length > 17) {
          if (await obd2.isListenToDataInitialed) {
            await Future.delayed(const Duration(milliseconds: 1500));
            vinNumber = decodeHexASCII3(vinNumber);
            var vin = VIN(number: vinNumber, extended: true);
            print(vinNumber);
            String? model = await vin.getModelAsync();
            String? manufacturer = vin.getManufacturer();
            try {
              carManufacturerLogo =
                  await findImageByName(vin.getManufacturer()!);
            } catch (e) {
              print(e);
            }

            setState(() {
              _isDeviceCompatible = true;
              carInformation['manufacturer'] = manufacturer;
              carInformation['model'] = model;
              //carManufacturerLogo = carManufacturerLogo;
            });
          }
        } else {
          setState(() {
            _isDeviceCompatible = false;
          });
        }
        setState(() {
          _isDeviceCompatibleButtonEnabled = true;
        });
      } catch (e) {
        print(e);
      }
    }
  }
}
