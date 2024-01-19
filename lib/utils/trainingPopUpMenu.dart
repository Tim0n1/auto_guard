import 'package:flatur/DB.dart';
import 'package:flutter/material.dart';

class MyList extends StatefulWidget {
  final Function(int)? onSelectedModel;
  final Function()? modelsCallback;
  //List<dynamic> models;
  final PostgresService? postgresService;
  MyList({this.onSelectedModel, this.postgresService, this.modelsCallback});

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  bool _isLoading = false;
  bool _isVisible = false;
  int _selectedItemIndex = -1;
  int? _currentModelIndex;
  List<dynamic>? models;

  TextEditingController _modelNameController = TextEditingController();

  void handleSelectedModel(int index) {
    // Implement your logic when a model is selected
  }

  void _showCreateNewModelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New Model'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Enter the details for the new model:'),
                    TextField(
                      controller: _modelNameController,
                      decoration: InputDecoration(labelText: 'Model Name'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    // Implement logic to create a new model
                    String modelName = _modelNameController.text;
                    if (modelName.isNotEmpty) {
                      await widget.postgresService
                          ?.addModel(modelName, 'Empty');
                      setState(() {
                        models = widget.modelsCallback!();
                        _isLoading = false;
                      });
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible; // Toggle visibility state
              });
            },
            child: Text(_isVisible ? 'Hide available models' : 'Select model'),
          ),
          Visibility(
            visible: _isVisible,
            child: Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: widget.modelsCallback!().length,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(height: 0, color: Colors.transparent);
                },
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(widget.modelsCallback!()[index][2]),
                    tileColor: _selectedItemIndex == index ? Colors.blue : null,
                    onTap: () {
                      setState(() {
                        if (_selectedItemIndex == index) {
                          _currentModelIndex = _selectedItemIndex;
                          widget.onSelectedModel!(_currentModelIndex!);
                          _isVisible = false;
                          print(_currentModelIndex);
                        } else {
                          _selectedItemIndex = index;
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
          Visibility(
            visible: _isVisible,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _showCreateNewModelDialog,
                      child: Text('Create new model'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedItemIndex != -1) {
                          setState(() {
                            _isLoading = true;
                            widget.postgresService?.deleteModel(
                                widget.modelsCallback!()[_selectedItemIndex]
                                    [2]);
                            _isLoading = false;
                          });
                        }
                      },
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: _isLoading,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
