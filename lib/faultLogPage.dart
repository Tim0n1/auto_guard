//create empty page
import 'package:flutter/material.dart';

class FaultLogPage extends StatefulWidget {
  const FaultLogPage({Key? key}) : super(key: key);

  @override
  _EmptyPageState createState() => _EmptyPageState();
}

class _EmptyPageState extends State<FaultLogPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('EmptyPage');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text('EmptyPage'),
      ),
    );
  }
}
