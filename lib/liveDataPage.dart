// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api

import 'package:flutter/material.dart';

class LiveDataPage extends StatefulWidget {
  @override
  _LiveDataPageState createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage> {
  List<Map<String, dynamic>> data = [
    {'parameter': 'O2%', 'value': '23.5'},
    {'parameter': 'Voltage', 'value': '12.3V'},
    {'parameter': 'Temperature', 'value': '78°C'},
    {'parameter': 'Emissions', 'value': 'Low'},
    // Add more parameters and values as needed
  ];

  void updateData() {
    // Simulating data update (replace this with your data update logic)
    setState(() {
      data = [
        {'parameter': 'O2%', 'value': '24.0'},
        {'parameter': 'Voltage', 'value': '12.8V'},
        {'parameter': 'Temperature', 'value': '80°C'},
        {'parameter': 'Emissions', 'value': 'Normal'},
        // Update other parameters and values as needed
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Data'),
      ),
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
          updateData();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
