// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import 'package:fl_chart/fl_chart.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';


import 'package:flutter/material.dart';

class LiveDataPage extends StatefulWidget {
  final Stream? stream;
  final StreamController? controller;
  const LiveDataPage({this.stream, this.controller});

  @override
  _LiveDataPageState createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> data = [];
  List<FlSpot> _chartData = [
    FlSpot(0, 0),
    FlSpot(1, 1),
    FlSpot(2, 2),
    FlSpot(3, 3)
  ];
  StreamController? eventController;
  StreamSubscription<dynamic>? _streamSubscription;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // if (widget.controller!.isClosed){
    //   widget.controller.
    // }
    StreamSubscription<dynamic> _streamSubscription =
        widget.controller!.stream.listen(
      (event) {
        updateData(event);
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
    //updateData(); // Update the data
  }

  void updateData(String event) async {
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
      _counter++;
      _chartData.add(
          FlSpot(_counter.toDouble(), double.parse(parsedJson[1]['response'])));
      if (_chartData.length > 20) {
        _chartData.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    widget.controller!
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
                            reservedSize: 50,
                            showTitles: true,
                            interval: 1000,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: 5,
                                getTitlesWidget: (value, titleMeta) {
                                  if (value.toInt() % 5 == 0) {
                                    return Text(value.toInt().toString());
                                  } else {
                                    return Text('');
                                  }
                                }))),
                    maxY: 8000,
                    minY: 0,
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData,
                        isCurved: true,
                        color: Colors.black.withAlpha(150),
                        belowBarData: BarAreaData(
                            show: true,
                            color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Call updateData() to simulate data changes
          //updateData();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
