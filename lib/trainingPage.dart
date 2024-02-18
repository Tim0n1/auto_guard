// ignore_for_file: prefer_const_constructors
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'utils/server_client.dart';
import 'utils/trainingPopUpMenu.dart';
import 'DB.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'utils/blinkingIcon.dart';

class TrainingPage extends StatefulWidget {
  final PostgresService? postgresService;
  final Function(bool, int)? serviceCallback;
  final Function() statesCallback;
  final Function() modelCallback;
  final Function(bool, int) trainingCallback;

  const TrainingPage(
      {this.postgresService,
      this.serviceCallback,
      required this.statesCallback,
      required this.modelCallback,
      required this.trainingCallback});

  @override
  _TrainingState createState() => _TrainingState();
}

class _TrainingState extends State<TrainingPage> {
  SharedPreferences? prefs;

  bool _isGatheringEnabled = false;
  bool _isTrainingEnabled = false;
  bool _isModelRefreshingEnabled = true;
  bool _isLoading = false;
  bool _isSnackBarVisible = false;
  bool _isSelectModelVisible = false;
  double _gatheringProgressValue = 0.0;
  double _trainingProgressValue = 0.0;
  bool _trainingButtonEnabled = false;
  int _dataSize = 0;
  int _currentModelSize = 0;
  bool _isInitial = false;
  bool _isModelListLoading = false;

  int _dotAnimationCount = 0;
  late Timer _dotAnimationTimer;
  late Timer _dataGatheringTimer;
  late Timer _trainingTimer;
  late Timer _refreshModelsTimer;

  List<dynamic> models = [];

  int _selectedModelIndex = -1;
  List<dynamic> _selectedModel = [];
  int modelId = 0;
  int maxSize = 0;

  @override
  void initState() {
    _startRefreshModels();
    super.initState();
    if (widget.statesCallback()['isDBinsertionEnabled']) {
      _isInitial = true;
      _dataGathering();
    }
    if (widget.statesCallback()['isTraining']) {
      _isInitial = true;
      _training();
    }
    _startDotAnimation();
    setMaxDataSize();
  }

  @override
  void dispose() {
    _isModelRefreshingEnabled = false;
    _dataGatheringTimer.cancel();
    _trainingTimer.cancel();
    _dotAnimationTimer.cancel();
    _refreshModelsTimer.cancel();
    super.dispose();
  }

  void setMaxDataSize() async {
    prefs = await SharedPreferences.getInstance();
    _dataSize = prefs?.getInt('size') ?? 0;
  }

  List<dynamic> modelsCallback() {
    return models;
  }

  bool isListLoadingCallback() {
    return _isModelListLoading;
  }

  void handleSelectedModel(int index) {
    print("selected model: $index");
    if (index != -1) {
      if (models[index][3] == models[index][4]) {
        print(12);
        _trainingButtonEnabled = true;
      } else {
        _trainingButtonEnabled = false;
      }
    }
    setState(() {
      _selectedModelIndex = index;
      _isSelectModelVisible = false;
    });
  }

  Future<dynamic> _getModels() async {
    try {
      dynamic models1 = await widget.postgresService?.getModels();
      if (models1[0] == 'r') {
        _isModelListLoading = true;
        models1 = [];
      } else {
        _isModelListLoading = false;
      }
      return models1;
    } catch (e) {
      print(e);
      return [];
    }
  }

  void _startRefreshModels() async {
    _refreshModelsTimer =
        Timer.periodic(Duration(milliseconds: 2000), (timer) async {
      if (_isModelRefreshingEnabled == false) {
        timer.cancel();
      }
      try {
        List<dynamic> new_models = await _getModels();
        setState(() {
          models = new_models;
        });
      } catch (e) {
        print(e);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );

    // Set the flag to indicate that the SnackBar is visible
    setState(() {
      _isSnackBarVisible = true;
    });

    // Schedule a callback to reset the flag after the SnackBar is dismissed
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isSnackBarVisible = false;
      });
    });
  }

  void _startDotAnimation() {
    _dotAnimationTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!_isGatheringEnabled) {
        // timer.cancel();
      } else {
        setState(() {
          // Toggle dot animation
          _dotAnimationCount = (_dotAnimationCount + 1) % 4;
        });
      }
    });
  }

  void _dataGathering() async {
    if (_isInitial) {
      _isInitial = false;
      try {
        modelId = widget.modelCallback();
        models = await _getModels();
        _selectedModel = models.firstWhere((element) => element[0] == modelId);
        _selectedModelIndex =
            models.indexWhere((element) => element[0] == modelId);
        modelId = _selectedModel[0];
      } catch (e) {
        print(e);
        return;
      }
    } else {
      if (widget.statesCallback()['isInternetEnabled'] == false) {
        _showSnackBar('Internet is not enabled');
        return;
      } else if (widget.statesCallback()['isDatabaseEnabled'] == false) {
        _showSnackBar('Database is not enabled');
        return;
      } else if (widget.statesCallback()['isDeviceCompatible'] == false) {
        _showSnackBar('Device is not compatible');
        return;
      } else if (_selectedModelIndex == -1 || models.isEmpty) {
        _showSnackBar('No model selected');
        return;
      }
      _selectedModel = models[_selectedModelIndex];
      modelId = _selectedModel[0];
    }

    if (_isGatheringEnabled) {
      print('stop gathering data');
      setState(() {
        widget.serviceCallback!(!_isGatheringEnabled, modelId);
        _isLoading = false;
        _isGatheringEnabled = false;
      });
      return;
    }

    if (_isLoading) {
      return;
    }

    //int? currentSize;
    prefs = await SharedPreferences.getInstance();

    //await prefs?.reload();
    maxSize = await widget.postgresService?.getModelMaxSize(modelId) ?? 0;
    // bind maxSize to model
    if (maxSize == 0) {
      _showSnackBar('Error: Model max_size is not set!');
      return;
    }

    setState(() {
      widget.serviceCallback!(true, modelId);
      _isGatheringEnabled = true;
      _gatheringProgressValue = 0.0;
      _trainingButtonEnabled =
          false; // Disable additional button initially// Reset second progress bar
    });

    setState(() {
      _isLoading = true;
    });
    const progressIncrement = 0.01;
    _dataGatheringTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        _currentModelSize = await widget.postgresService?.getModelSize(modelId);
        print('currentSize: $_currentModelSize');
        print('maxSize: $maxSize');
        if (_isGatheringEnabled == false) {
          timer.cancel();
          return;
        }
        if (_currentModelSize == maxSize) {
          setState(() {
            _isGatheringEnabled = false;
            widget.serviceCallback!(_isGatheringEnabled, modelId);
            _isLoading = false;
            _trainingButtonEnabled = true; // Enable additional button
            _gatheringProgressValue = 1.0;
          });
          timer.cancel();
          return;
        }
        setState(() {
          print('progressValue: $_gatheringProgressValue');
          _gatheringProgressValue =
              (_currentModelSize.toDouble() / maxSize.toDouble());
          print(_gatheringProgressValue);
        });
      } catch (e) {
        print(e);
      }
    });
  }

  void _training() async {
    if (_isInitial) {
      _isInitial = false;
      try {
        modelId = widget.modelCallback();
        models = await _getModels();
        _selectedModel = models.firstWhere((element) => element[0] == modelId);
        _selectedModelIndex =
            models.indexWhere((element) => element[0] == modelId);
        modelId = _selectedModel[0];
        setState(() {
          _trainingButtonEnabled = true;
        });
      } catch (e) {
        print(e);
        return;
      }
    } else {
      if (widget.statesCallback()['isInternetEnabled'] == false) {
        _showSnackBar('Internet is not enabled');
        return;
      } else if (widget.statesCallback()['isDatabaseEnabled'] == false) {
        _showSnackBar('Database is not enabled');
        return;
      } else if (widget.statesCallback()['isDeviceCompatible'] == false) {
        _showSnackBar('Device is not compatible');
        return;
      } else if (_selectedModelIndex == -1 || models.isEmpty) {
        _showSnackBar('No model selected');
        return;
      }
      _selectedModel = models[_selectedModelIndex];
      modelId = _selectedModel[0];
    }

    TrainingClient client = TrainingClient();

    if (_isTrainingEnabled) {
      print('stop training');
      await client.stopTraining();
      setState(() {
        widget.trainingCallback(!_isTrainingEnabled, modelId);
        _isTrainingEnabled = false;
      });
      return;
    }

    bool trainingStarted = await client.startTraining(modelId);
    print(trainingStarted);
    if (trainingStarted) {
      setState(() {
        _isTrainingEnabled = true;
        widget.trainingCallback(_isTrainingEnabled, modelId);
      });
    } else {
      setState(() {
        _isTrainingEnabled = false;
      });
      return;
    }
    double progressValue = 0;
    _trainingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        if (_isTrainingEnabled) {
          print('getting progress');
          progressValue = await client.getProgress();
          setState(() {
            _trainingProgressValue = progressValue;
          });
          if (_trainingProgressValue >= 1.0) {
            print(modelId);
            setState(() {
              widget.trainingCallback(!_isTrainingEnabled, modelId);
              _isTrainingEnabled = false;
            });
            timer.cancel();
            return;
          }
        }
      } catch (e) {
        print(e);
        timer.cancel();
        return;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isSnackBarVisible == true) {
                      return;
                    } else {
                      print('gathering data');
                      _dataGathering();
                    }
                  },
                  label: Text(_isGatheringEnabled
                      ? 'Stop gathering data'
                      : 'Start gathering data'),
                  icon:
                      Icon(_isGatheringEnabled ? Icons.stop : Icons.play_arrow),
                ),
                if (!_isGatheringEnabled)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle the action for the second additional button
                    },
                    label: Text('Delete data'),
                    icon: Icon(Icons.delete),
                  ),
              ],
            ),
            SizedBox(height: 40),
            //_additionalButtonEnabled // Render additional button only if progress is 100%
            ElevatedButton.icon(
              onPressed: _trainingButtonEnabled ? _training : null,
              label: Text(
                  !_isTrainingEnabled ? 'Start training' : 'Stop Training'),
              icon: Icon(Icons.play_circle),
            ),
            // if (_isTrainingEnabled)
            // ElevatedButton(
            //   onPressed: _trainingButtonEnabled ? _training : null,
            //   child: Text('Start training'),
            // ),
            // : SizedBox(), // Placeholder if the button is not enabled
            SizedBox(height: 20),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                if (_isSnackBarVisible) {
                  return;
                }
                if (_isGatheringEnabled) {
                  _showSnackBar('Can\'t change model when gathering data!');
                  return;
                }
                setState(() {
                  _isSelectModelVisible = !_isSelectModelVisible;
                });
              },
              label: Text(_isSelectModelVisible
                  ? 'Hide available models'
                  : 'Select model'),
              icon: !_isSelectModelVisible
                  ? Icon(Icons.select_all)
                  : Icon(Icons.hide_source),
            ),

            Flexible(
              child: Visibility(
                maintainState: true,
                visible: _isSelectModelVisible,
                child: MyList(
                  modelsCallback: modelsCallback,
                  isModelListLoading: isListLoadingCallback,
                  onSelectedModel: handleSelectedModel,
                  postgresService: widget.postgresService,
                  isVisible: _isSelectModelVisible,
                ),
              ),
            ),
            SizedBox(height: 50),
            Visibility(
              visible: !_isSelectModelVisible,
              child: Flexible(
                child: Container(
                  alignment: Alignment.center,
                  child: CircularPercentIndicator(
                    radius: 100.0,
                    lineWidth: 10.0,
                    percent: _isTrainingEnabled
                        ? _trainingProgressValue
                        : _gatheringProgressValue,
                    header: Text(
                      _isTrainingEnabled
                          ? "Training..."
                          : (_isGatheringEnabled
                              ? "Gathering data${'.' * _dotAnimationCount}"
                              : ""),
                      style: TextStyle(fontSize: 18),
                    ),
                    center: BlinkingIcon(
                        widget.statesCallback()['isDeviceCompatible']),
                    backgroundColor: Colors.grey,
                    progressColor: Colors.deepPurple.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        )),
        Positioned(
          bottom: 3.0,
          right: 12.0,
          child: Text(
            (_selectedModelIndex == -1 || models.isEmpty) && (!_isGatheringEnabled && !_isTrainingEnabled)
                ? 'No model selected'
                : (!_isGatheringEnabled
                    ? 'Selected model: ${models[_selectedModelIndex][2]}\n(${models[_selectedModelIndex][3]}) ${models[_selectedModelIndex][5] ? "Trained" : "Untrained"}\nMax size: $_dataSize'
                    : ('Selected model: ${_selectedModel[2]}\n(${_currentModelSize}) ${_selectedModel[5]}\nMax size: $maxSize ')),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Visibility(
                    visible: widget.statesCallback()['isInternetEnabled'],
                    child: Icon(
                      Icons.wifi,
                      color: Colors.green,
                    ),
                  ),
                  Visibility(
                    visible: !widget.statesCallback()['isInternetEnabled'],
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
                    visible: widget.statesCallback()['isDatabaseEnabled'],
                    child: Icon(
                      Icons.satellite_alt,
                      color: Colors.green,
                    ),
                  ),
                  Visibility(
                    visible: !widget.statesCallback()['isDatabaseEnabled'],
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
                    visible: widget.statesCallback()['isDeviceCompatible'],
                    child: Icon(
                      Icons.car_repair,
                      color: Colors.green,
                    ),
                  ),
                  Visibility(
                    visible: !widget.statesCallback()['isDeviceCompatible'],
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
            ))
      ]),
    );
  }
}
