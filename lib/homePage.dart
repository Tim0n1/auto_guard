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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'dart:ui';
import 'settingsScreen.dart';
import 'obd2.dart';
import 'package:postgres/postgres.dart';
import 'DB.dart';
import 'utils/blinkingIcon.dart';
import 'utils/findImage.dart';
import 'utils/trainingPopUpMenu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.controller});
  @override
  _HomeState createState() => _HomeState();
  final StreamController? controller;
}

class _HomeState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Callback functions for training page
  void _enableInsertionCallback(bool isEnabled) {
    _isDBinsertionEnabled = isEnabled;
  }

  Map<String, bool> _connectionsStateCallback() {
    return {
      'isInternetEnabled': _isInternetEnabled,
      'isDatabaseEnabled': _isDatabaseConnected,
      'isDeviceCompatible': _isDeviceCompatible,
    };
  }

  String currentVersion = 'v0.1';

  int? id;

  bool _isInternetEnabled = false;
  bool _isDatabaseConnected = false;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _connectedDevice;
  bool _bluetoothPermissionGranted = false;
  bool _notificationsPermissionsGranted = false;

  PostgresService postgresService = PostgresService();

  bool _serviceRunning = true;
  bool _isDeviceCompatible = false;
  bool _isDeviceCompatibleButtonEnabled = true;
  bool _isDBinsertionEnabled = false;

  Map<String, String?> carInformation = {
    "manufacturer": 'Toyota',
    "model": null
  };
  String? carManufacturerLogo = '';
  String vinNumber = '';
  Obd2Plugin obd2 = Obd2Plugin();

  String currentState = '';

  //Stream<void>? _stream;
  //StreamController _eventController = StreamController.broadcast();

  late Timer _deviceRefreshTimer;
  static const int _refreshInterval = 3; // Refresh interval in seconds

  int _currentIndex = 0;

  Timer? _timer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // this will be used as notification channel id
  static const notificationChannelId = 'my_foreground';
// this will be used for notification id, So you can update your custom notification with this id.
  static const notificationId = 888;

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

  Future<void> startParamsExtraction() async {
    StreamController _eventController = widget.controller!;

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 1000));
      //print(_serviceRunning);
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
            obd2.setOnDataReceived((command, response, requestCode) {
              if (!_eventController.isClosed) {
                _eventController.add(response);
              } else {
                print("startirame");
                _eventController = StreamController.broadcast();
              }
              List<dynamic> parsedJson = [];
              parsedJson = json.decode(response);
              vinNumber = parsedJson[parsedJson.length - 1]['response'];
              if (_isDatabaseConnected != false) {
                if (_isDBinsertionEnabled) {
                  print('inserting');
                  postgresService
                      .insert(parsedJson.sublist(0, parsedJson.length - 1));
                }
              } else {
                print('no DB connection');
              }
              flutterLocalNotificationsPlugin.show(
                notificationId,
                'S',
                '${DateTime.now()}',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    notificationChannelId,
                    'MY FOREGROUND SERVICE',
                    icon: 'ic_bg_service_small',
                    ongoing: false,
                  ),
                ),
              );

              //print("$command => $response");
            });
          }
          while (await obd2.hasConnection && _connectedDevice != null) {
            String params = await StringJson().getChosenParams();
            await Future.delayed(
                Duration(milliseconds: await obd2.getParamsFromJSON(params)));
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
              padding: const EdgeInsets.only(
                  top: 20), // Adjust top padding as needed
              child: Image.asset(
                'lib/images/logotobart.png', // Replace with your logo asset path
                width: 150, // Adjust width as needed
                height: 150, // Adjust height as needed
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
                //     child: Icon(
                //   Icons.car_repair,
                //   size: 50,
                //   color: _isDeviceCompatible
                //       ? Colors.black.withOpacity(0.1)
                //       : Colors.red.withOpacity(0.5),
                // )
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BackgroundServiceScreen(
                                        connectedDevice: _connectedDevice,
                                      )));
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
      await Future.delayed(const Duration(milliseconds: 2000));
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
            carManufacturerLogo = await findImageByName(vin.getManufacturer()!);
          } catch (e) {
            print(e);
          }
          // print(model);
          // print(vin.getManufacturer());
          // print(vinNumber);

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
    }
  }
}
