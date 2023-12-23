// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'utils/evenrControllerProvider.dart';

import 'package:flutter/material.dart';

class LiveDataPage extends StatefulWidget {
  final Stream? stream;
  final StreamController? controller;
  const LiveDataPage({this.stream, this.controller});

  @override
  _LiveDataPageState createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> data = [];
  StreamController? eventController;
  StreamSubscription<dynamic>? _streamSubscription;

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
        print("received data: $event");
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
      body: Container(
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
