// ignore_for_file: prefer_const_constructors

import 'package:flatur/inferencePage.dart';
import 'package:flatur/liveDataPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flatur/trainingPage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

String currentVersion = 'v0.1';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        primaryColor: Colors.pink,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothDevice? _connectedDevice;
  bool _bluetoothPermissionGranted = false;
  bool _notificationsPermissionsGranted = false;

  late Timer _deviceRefreshTimer;
  static const int _refreshInterval = 3; // Refresh interval in seconds

  bool isConnected = false; // New variable to track connection status

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _startDeviceRefreshTimer();
  }

  @override
  void dispose() {
    _deviceRefreshTimer.cancel();
    super.dispose();
  }

  Future<bool> checkAndRequestPermissions() async {
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothAdvertise.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted) {
      return true;
    } else {
      return false;
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
        Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
      _updateConnectedDevice(); // Update connected device status
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Doctor $currentVersion'),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: 20), // Adjust top padding as needed
              child: Image.asset(
                'lib/images/logotobart.png', // Replace with your logo asset path
                width: 150, // Adjust width as needed
                height: 150, // Adjust height as needed
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrainingPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50), // Adjust padding
                    textStyle: TextStyle(fontSize: 18), // Adjust text size
                    minimumSize: Size(200, 60), // Adjust minimum button size
                  ),
                  child: Text('Training mode'),
                ),
                SizedBox(height: 16), // Add spacing between buttons
                ElevatedButton(
                  onPressed: _connectedDevice != null ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BackgroundServiceScreen(
                                  connectedDevice: _connectedDevice,
                                )));
                  }: null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50), // Adjust padding
                    textStyle: TextStyle(fontSize: 18), // Adjust text size
                    minimumSize: Size(200, 60), // Adjust minimum button size
                  ),
                  child: Text('Inference mode'),
                ),
                SizedBox(height: 80), // Add spacing between buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrainingPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50), // Adjust padding
                    textStyle: TextStyle(fontSize: 18), // Adjust text size
                    minimumSize: Size(200, 60), // Adjust minimum button size
                  ),
                  child: Text('Fault log'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiveDataPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: 20, horizontal: 50), // Adjust padding
                    textStyle: TextStyle(fontSize: 18), // Adjust text size
                    minimumSize: Size(200, 60), // Adjust minimum button size
                  ),
                  child: Text('Live data'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            child: Container(
              padding: EdgeInsets.all(8),
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
                  SizedBox(height: 8), // Add spacing between texts
                  Text(
                    isConnected ? 'Connected Device:' : '',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_connectedDevice?.name ?? 'Not connected'}',
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 15.0, right: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Check OBD compatibility',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      // Add any other text styles as needed
                    ),
                  ),
                ),
                SizedBox(
                    width: 8), // Add some space between the button and text
                FloatingActionButton(
                  onPressed: () {
                    // Add your action when the button is pressed here
                  },
                  foregroundColor: null,
                  backgroundColor: Colors.transparent,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Handle button tap if needed
                      },
                      child: Image.asset(
                        'lib/images/obd_icon.png', // Replace with your icon asset path
                        // Adjust height as needed
                        // You can also use other properties available in Image.asset
                      ),
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
}
