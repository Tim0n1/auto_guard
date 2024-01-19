// ignore_for_file: prefer_const_constructors
import 'utils/trainingPopUpMenu.dart';
import 'DB.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class TrainingPage extends StatefulWidget {
  final PostgresService? postgresService;
  final Function(bool)? callback;

  const TrainingPage({this.postgresService, this.callback});

  @override
  _TrainingState createState() => _TrainingState();
}

class _TrainingState extends State<TrainingPage> {
  bool _isGatheringEnabled = false;
  bool _isModelRefreshingEnabled = true;
  bool _isLoading = false;
  double _progressValue = 0.0;
  bool _additionalButtonEnabled = false;
  bool _secondProgressBarStarted = false;
  double _secondProgressValue = 0.0;

  List<dynamic> models = [];

  int _selectedModelIndex = -1;

  @override
  void initState() {
    super.initState();
    _startRefreshModels();
  }

  @override
  void dispose() {
    _isModelRefreshingEnabled = false;
    super.dispose();
  }

  List<dynamic> modelsCallback() {
    return models;
  }

  void handleSelectedModel(int index) {
    print("selected model: $index");

    setState(() {
      _selectedModelIndex = index;
    });
  }

  Future<dynamic> _getModels() async {
    try {
      models = await widget.postgresService?.getModels();
      //print(1);
      return models;
    } catch (e) {
      print(e);
      return [];
    }
  }

  void _startRefreshModels() async {
    while (true) {
      await Future.delayed(Duration(seconds: 2));
      if (_isModelRefreshingEnabled == false) {
        break;
      }
      try {
        print(2);
        List<dynamic> new_models = await _getModels();
        setState(() {
          models = new_models;
        });
      } catch (e) {
        print(e);
      }
    }
  }

  void _dataGathering() {
    setState(() {
      widget.callback!(true);
      _isLoading = true;
      _progressValue = 0.0;
      _additionalButtonEnabled = false; // Disable additional button initially
      _secondProgressBarStarted = false; // Reset second progress bar
      _secondProgressValue = 0.0;
    });

    const progressIncrement = 0.02;
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      try {
        setState(() {
          _progressValue += progressIncrement;
        });
        if (_progressValue >= 1.0) {
          timer.cancel();
          _isLoading = false;
          _additionalButtonEnabled = true; // Enable the additional button
        }
      } catch (e) {
        print(e);
      }
    });
  }

  void _training() {
    setState(() {
      _secondProgressBarStarted = true; // Start the second progress bar
    });

    const secondProgressIncrement = 0.02;
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      try {
        setState(() {
          _secondProgressValue += secondProgressIncrement;
        });
        if (_secondProgressValue >= 1.0) {
          timer.cancel();
          _secondProgressBarStarted = false; // Finish the second progress bar
        }
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //return MyList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Training'),
      ),
      body: Stack(children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _secondProgressBarStarted
                    ? null
                    : (_isLoading ? null : _dataGathering),
                child: Text(_isLoading ? 'Loading...' : 'Start data gathering'),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progressValue,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 40),
              //_additionalButtonEnabled // Render additional button only if progress is 100%
              ElevatedButton(
                onPressed: _additionalButtonEnabled ? _training : null,
                child: Text('Start training'),
              ),
              // : SizedBox(), // Placeholder if the button is not enabled
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: _secondProgressValue,
                minHeight: 10,
                backgroundColor: const Color.fromARGB(255, 250, 218, 218),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 40),
              Expanded(
                child: MyList(
                  onSelectedModel: handleSelectedModel,
                  postgresService: widget.postgresService,
                  modelsCallback: modelsCallback,
                ),
              )
            ],
          ),
        ),
        Positioned(
          bottom: 8.0,
          right: 8.0,
          child: Text(
            _selectedModelIndex.toString(), // Add your desired label text here
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }
}
