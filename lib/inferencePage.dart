import 'package:flatur/DB.dart';
import 'package:flutter/material.dart';

class TrainableModels extends StatefulWidget {
  final void Function(String?) onItemSelected;
  final PostgresService postgresService;
  TrainableModels({required this.onItemSelected, required this.postgresService});
  @override
  _TrainableModelsState createState() => _TrainableModelsState();
}

class _TrainableModelsState extends State<TrainableModels> {
  List<dynamic> models = [];
  dynamic selectedItem;

  @override
  void initState() {
    super.initState();
    getTrainedModels();
  }

  void getTrainedModels() async {
    List<dynamic> allModels = await widget.postgresService.getModels();
    for (int i = 0; i < allModels.length; i++) {
      if (allModels[i][5] == true) {
        setState(() {
          models.add(allModels[i]);
        });
      }
    }
    print(models);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select model'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: models.length,
          itemBuilder: (BuildContext context, int index) {
            return RadioListTile(
              title: Text(models[index][2]),
              value: models[index][2],
              groupValue: selectedItem,
              onChanged: (dynamic value) {
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
            Navigator.of(context).pop(); // Close the dialog without selecting
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onItemSelected(selectedItem);
            Navigator.of(context).pop();
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
