// ignore_for_file: prefer_const_constructors
import 'package:obd2_plugin/obd2_plugin.dart';
import 'dart:async';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'obd2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flatur/obd2.dart';

class BackgroundServiceScreen extends StatefulWidget {
  final BluetoothDevice? connectedDevice;

  const BackgroundServiceScreen({required this.connectedDevice});

  @override
  _BackgroundServiceScreenState createState() =>
      _BackgroundServiceScreenState();
}

class _BackgroundServiceScreenState extends State<BackgroundServiceScreen> {
  bool _serviceRunning = false;
  //String jsonParamsPath = 'lib\\params.json';
  String params = StringJson().params;

  Obd2Plugin obd2 = Obd2Plugin();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final service = FlutterBackgroundService();

  // this will be used as notification channel id
  static const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
  static const notificationId = 888;

  @override
  void initState() {
    super.initState();
    // obd2.getConnection(widget.connectedDevice!, (connection) {
    //   print("connected to bluetooth device.");
    // }, (message) {
    //   print("error in connecting: $message");
    // });
    //print(invokePlatformCode());
    initializeService();

    print(11);
  }

  Future<void> initializeService() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId, // id
      'MY FOREGROUND SERVICE', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart, autoStart: false, isForegroundMode: true,
          notificationChannelId:
              notificationChannelId, // this must match with notification channel you created above.
          initialNotificationTitle: 'AWESOME SERVICE',
          initialNotificationContent: 'Initializing',
          foregroundServiceNotificationId: notificationId,
          //obd2: obd2
        ),
        iosConfiguration: IosConfiguration());
  }

  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    Obd2Plugin obd2 = Obd2Plugin();
    String params = StringJson().params;

    Timer.periodic(Duration(seconds: 3), (timer) async {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // var a = await obd2.getParamsFromJSON(params);

      // obd2.setOnDataReceived((command, response, requestCode) {
      //   print("$command => $response");
      // });

      flutterLocalNotificationsPlugin.show(
        notificationId,
        'COOL SERVICE',
        'Awesome ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'MY FOREGROUND SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
      print('backgrounda cuka');
    });
  }

  void _startOrStopService() {
    if (_serviceRunning) {
      service.invoke('stopService');
      setState(() {
        _serviceRunning = false;
      });
    } else {
      //initializeService();
      service.startService();
      service.invoke('startService');

      setState(() {
        _serviceRunning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Service Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startOrStopService,
          child: Text(_serviceRunning ? 'Stop Service' : 'Start Service'),
        ),
      ),
    );
  }
}
