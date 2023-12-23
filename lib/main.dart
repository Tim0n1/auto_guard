// ignore_for_file: prefer_const_constructors, non_constant_identifier_names

import 'dart:convert';
import 'package:flatur/testtabController.dart';
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

import 'homePage.dart';
import 'liveDataPage.dart';
import 'faultLogPage.dart';

String currentVersion = 'v0.1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Retrieve the SharedPreferences instance
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if the app is opened for the first time
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  // If it's the first time, generate and save the ID
  if (isFirstTime) {
    // Generate an ID (for example, a random integer)
    int generatedId = DateTime.now().millisecondsSinceEpoch % 1000000;

    // Save the ID to SharedPreferences
    prefs.setInt('generatedId', generatedId);

    // Set isFirstTime to false to indicate that it's not the first time anymore
    prefs.setBool('isFirstTime', false);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        primaryColor: Colors.pink,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: ZoomPageTransitionsBuilder(
              allowEnterRouteSnapshotting: false,
            ),
          },
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  StreamController _eventController = StreamController.broadcast();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Doctor $currentVersion'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: <Widget>[
          HomeScreen(controller:_eventController), // Replace with your screen
          LiveDataPage(controller: _eventController), // Replace with your screen
          FaultLogPage(), // Replace with your screen
          // Add more screens if you have them
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          _pageController.animateToPage(index,
              duration: Duration(milliseconds: 200), curve: Curves.easeIn);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_sharp),
            label: 'Live data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Fault log',
          ),
          // Add more items if you have them
        ],
      ),
    );
  }
}
