// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:async';

class TrainingPage extends StatefulWidget {
  @override
  _TrainingState createState() => _TrainingState();
}

class _TrainingState extends State<TrainingPage> {
  bool _isLoading = false;
  double _progressValue = 0.0;
  bool _additionalButtonEnabled = false;
  bool _secondProgressBarStarted = false;
  double _secondProgressValue = 0.0;

  void _simulateProgress() {
    setState(() {
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

  void _additionalButtonAction() {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Button Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height:50),
            ElevatedButton(
              onPressed: _secondProgressBarStarted? null: (_isLoading ? null : _simulateProgress),
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
              onPressed: _additionalButtonEnabled? _additionalButtonAction: null,
              child: Text('Start training'),
            ),
            // : SizedBox(), // Placeholder if the button is not enabled
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: _secondProgressValue,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            )
          ],
        ),
      ),
    );
  }
}
