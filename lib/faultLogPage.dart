//create empty page
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'DB.dart';
import 'package:flutter/material.dart';

class FaultLogPage extends StatefulWidget {
  const FaultLogPage({Key? key}) : super(key: key);

  @override
  _FaultLogPageState createState() => _FaultLogPageState();
}

class _FaultLogPageState extends State<FaultLogPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    refreshFaults();
  }

  late Timer _refreshFaultsTimer;
  SharedPreferences? prefs;
  PostgresService? postgresService;

  List<dynamic> faults = [

  ];

  void refreshFaults() async {
    prefs = await SharedPreferences.getInstance();
    int? Id = prefs?.getInt('generatedId');
    postgresService = PostgresService(id: Id);
    await postgresService?.getConnection();
    _refreshFaultsTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      List<dynamic> new_faults = await postgresService?.getFaults();
      setState(() {
        faults = new_faults;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: faults.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            elevation: 8.0,
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Container(
                decoration: const BoxDecoration(),
                child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    leading: Container(
                      padding: EdgeInsets.only(right: 12.0),
                      decoration: new BoxDecoration(
                          border: new Border(right: new BorderSide())),
                      child: Icon(Icons.delete),
                    ),
                    title: Text(() {
                      dynamic fault = faults[index];
                      String score = fault[fault.length - 2].toStringAsFixed(2);
                      DateTime date = fault[fault.length - 1];
                      int day = date.day;
                      int month = date.month;
                      int year = date.year;
                      int hour = date.hour;
                      int minute = date.minute;

                      return '${score}             |${day}-${month}-${year} ${hour}:${minute}|';
                    }()
                        //'${faults[index][faults[index].length - 2].toStringAsFixed(2)}   ${faults[index][faults[index].length - 1].hour}',
                        //style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                    // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

                    subtitle: Row(
                      children: <Widget>[
                        Icon(Icons.linear_scale),
                        Text(faults[index][2].toString())
                      ],
                    ),
                    trailing: Icon(Icons.keyboard_arrow_right))),
          );
        },
      ),
    );
  }
}
