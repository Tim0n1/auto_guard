// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import 'package:fl_chart/fl_chart.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveDataPage extends StatefulWidget {
  final StreamController? controller1;
  final StreamController? controller2;
  const LiveDataPage({this.controller1, this.controller2});

  @override
  _LiveDataPageState createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  SharedPreferences? prefs;
  List<Map<String, dynamic>> data = [];
  List<FlSpot> _chartData = [];
  StreamSubscription<dynamic>? _streamSubscription1;
  StreamSubscription<dynamic>? _streamSubscription2;
  bool isInferencing = false;
  bool isInitialInference = true;
  int _counter = 0;
  int threshold = 0;

  @override
  void initState() {
    super.initState();
    // if (widget.controller1!.isClosed){
    //   widget.controller1.
    // }
    StreamSubscription<dynamic> _streamSubscription1 =
        widget.controller1!.stream.listen(
      (event) {
        updateParameters(event);
        //print("received data: $event");
      },
      onError: (dynamic error) {
        // Handle errors, if any
        print('Error occurred: $error');
      },
      onDone: () {
        // Handle when the stream is done (closed)
        print('StreamController closed');
      },
    );
    // Start a periodic timer to update data every 2 seconds
    //Timer.periodic(Duration(seconds: 2), (timer) {
    //updateParameters(); // Update the data

    StreamSubscription<dynamic> _streamSubscription2 =
        widget.controller2!.stream.listen(
      (event) {
        if (event[0] == 1) {
          if (!isInferencing) {
            setState(() {
              _chartData.clear();
              _counter = 0;
            });
          }
          isInferencing = true;
          print(event[1]);
          updatePredictions(event[1]);
        } else {
          isInferencing = false;
        }
      },
      onError: (dynamic error) {
        // Handle errors, if any
        print('Error occurred: $error');
      },
      onDone: () {
        // Handle when the stream is done (closed)
        print('StreamController closed');
      },
    );
  }

  void updateParameters(String event) async {
    data = [];
    List<dynamic> parsedJson = [];
    parsedJson = json.decode(event);
    setState(() {
      for (int i = 0; i < parsedJson.length - 1; i++) {
        data.insert(i, {
          'parameter': parsedJson[i]['title'],
          'value': "${parsedJson[i]['response']} ${parsedJson[i]['unit']}"
        });
      }
      if (!isInferencing) {
        _counter++;
        _chartData.add(FlSpot(
            _counter.toDouble(), double.parse(parsedJson[1]['response'])));
        if (_chartData.length > 20) {
          _chartData.removeAt(0);
        }
      }
    });
  }

  void updatePredictions(double data) async {
    prefs ??= await SharedPreferences.getInstance();
    setState(() {
        threshold = prefs!.getInt('threshold')!;
    });
    _counter++;
    _chartData.add(FlSpot(_counter.toDouble(), data));
    if (_chartData.length > 20) {
      _chartData.removeAt(0);
    }
  }

  @override
  void dispose() {
    _streamSubscription1?.cancel();
    widget.controller1!
        .close(); // Close the StreamController when disposing the widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: DataTable(
                      columnSpacing: 20.0,
                      headingRowHeight: 40.0,
                      columns: [
                        DataColumn(label: Text('Parameter')),
                        DataColumn(label: Text('Value')),
                      ],
                      rows: data.map((rowData) {
                        return DataRow(cells: [
                          DataCell(Text(rowData['parameter'].toString())),
                          DataCell(Text(rowData['value'].toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: 250, // Set your desired height for the chart
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            getTitlesWidget: (value, meta) {
                              if (isInferencing) {
                                return Text('   ${value.toInt().toString()}%');
                              } else {
                                return Text('   ${value.toString()[0]}K');
                              }
                            },
                            reservedSize: 50,
                            showTitles: true,
                            interval: isInferencing ? 25 : 1000,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: 5,
                                getTitlesWidget: (value, titleMeta) {
                                  if (value.toInt() % 5 == 0) {
                                    // ignore: unnecessary_string_interpolations
                                    return Text('${value.toInt().toString()}');
                                  } else {
                                    return Text('');
                                  }
                                }))),
                    maxY: isInferencing ? 100 : 8000,
                    minY: 0,
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData,
                        isCurved: true,
                        color: Colors.black.withAlpha(150),
                        belowBarData: BarAreaData(
                            show: true,
                            color: isInferencing
                                ? Colors.red.withOpacity(0.5)
                                : Colors.deepPurple.withOpacity(0.3)),
                      ),
                    ],
                    extraLinesData: isInferencing
                        ? ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: threshold.toDouble(),
                                color: Colors.red,
                                strokeWidth: 2,
                                dashArray: [
                                  5,
                                  5
                                ], // Set dash array for dashed line (optional)
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call updateParameters() to simulate data changes
          //updateParameters();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
