// ignore_for_file: prefer_const_constructors
import 'package:obd2_plugin/obd2_plugin.dart';
import 'dart:async';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'dart:convert';
import 'dart:io';
import 'obd2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
//import 'package:flatur/obd2.dart';

//Obd2Plugin obd2 = Obd2Plugin();

class BackgroundServiceScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;
  final Stream<void>? stream;

  const BackgroundServiceScreen(
      {required this.connectedDevice, this.stream});

  @override
  _BackgroundServiceScreenState createState() =>
      _BackgroundServiceScreenState();
}

class _BackgroundServiceScreenState extends State<BackgroundServiceScreen> {

  bool _serviceRunning1 = false;
  bool _backgroundRunning = false;
  //String jsonParamsPath = 'lib\\params.json';
  String params = StringJson().params;

  Timer? _timer;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    print(11);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // void initializeService() async {
  //   final androidConfig = FlutterBackgroundAndroidConfig(
  //     notificationTitle: "flutter_background example app",
  //     notificationText:
  //         "Background notification for keeping the example app running in the background",
  //     notificationImportance: AndroidNotificationImportance.Default,
  //     notificationIcon: AndroidResource(
  //         name: 'background_icon',
  //         defType: 'drawable'), // Default is ic_launcher from folder mipmap
  //   );
  //   bool success =
  //       await FlutterBackground.initialize(androidConfig: androidConfig);
  // }

  void _startOrStopService() async {
    if (_serviceRunning1) {
      setState(() {
        _serviceRunning1 = false;
      });
    } else {
      setState(() {
        _serviceRunning1 = true;
      });
      //initializeService();
      //obd2.connection?.close();
    }
  }

  // void _startInBackground() async {
  //   if (_backgroundRunning) {
  //     await FlutterBackground.disableBackgroundExecution();
  //     setState(() {
  //       _backgroundRunning = false;
  //     });
  //   } else {
  //     bool hasPermissions = await FlutterBackground.hasPermissions;
  //     print(hasPermissions);
  //     if (hasPermissions) {
  //       bool success = await FlutterBackground.enableBackgroundExecution();
  //       print(success);
  //     }
  //     setState(() {
  //       _backgroundRunning = true;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    //super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Background Service Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startOrStopService,
          child: Text(_serviceRunning1 ? 'Stop Service' : 'Start Service'),
        ),
      ),
    );
  }
}
