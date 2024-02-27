import 'package:flatur/DB.dart';
import 'package:flutter/material.dart';

class TrainableModels extends StatefulWidget {
  final void Function(List<dynamic>) onItemSelected;
  final PostgresService postgresService;
  final List<dynamic> model;
  bool isInferencing;
  TrainableModels(
      {required this.onItemSelected,
      required this.postgresService,
      required this.model,
      required this.isInferencing});
  @override
  _TrainableModelsState createState() => _TrainableModelsState();
}

class _TrainableModelsState extends State<TrainableModels> {
  List<dynamic> models = [];
  dynamic selectedItem;
  int? selectedIndex;

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
  }

  Widget build(BuildContext context) {
    if (widget.isInferencing) {
      return AlertDialog(
        title: Text('Inferencing...'),
        content: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(
                                right: 8), // Adjust the margin as needed
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                              '${widget.model[2]}    (${widget.model[3]})'),
                        ],
                      ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pop(); // Close the dialog without stopping inferencing
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onItemSelected([]);
              // Add code here to stop inferencing
              Navigator.of(context)
                  .pop(); // Close the dialog after stopping inferencing
            },
            child: Text('Stop'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Text('Select model'),
        content: Container(
          constraints: BoxConstraints(maxHeight: 300),
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: models.length,
            itemBuilder: (BuildContext context, int index) {
              return RadioListTile(
                title: Text(models[index][2]),
                value: index, // Use index as the value for each item
                groupValue: selectedIndex,
                onChanged: (dynamic value) {
                  setState(() {
                    selectedIndex =
                        value; // Update selectedIndex with the selected index
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
              if (selectedIndex != null) {
                widget.onItemSelected(models[selectedIndex!]);
              }
              Navigator.of(context).pop();
            },
            child: Text('Start'),
          ),
        ],
      );
    }
  }
}
