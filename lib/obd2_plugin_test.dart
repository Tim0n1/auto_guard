import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selectable Items Demo',
      home: SelectableItemsScreen(),
    );
  }
}

class SelectableItemsScreen extends StatefulWidget {
  @override
  _SelectableItemsScreenState createState() => _SelectableItemsScreenState();
}

class _SelectableItemsScreenState extends State<SelectableItemsScreen> {
  List<String> items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];

  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Item'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showSelectableItems(context);
          },
          child: Text('Choose Item'),
        ),
      ),
    );
  }

  void _showSelectableItems(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an Item'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return RadioListTile(
                  title: Text(items[index]),
                  value: items[index],
                  groupValue: selectedItem,
                  onChanged: (String? value) {
                    setState(() {
                      selectedItem = value;
                    });
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Perform any action needed when dialog is closed
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
