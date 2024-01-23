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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Model'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Enter the details for the new model:'),
                    TextField(
                      controller: _modelNameController,
                      decoration: const InputDecoration(labelText: 'Model Name'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    // Implement logic to create a new model
                    String modelName = _modelNameController.text;
                    bool modelFound = false;

                    if (modelName.isNotEmpty) {
                      // Simulate an asynchronous operation (replace with actual logic)

                      widget.postgresService?.addModel(modelName, 'Empty');

                      while (!modelFound) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        models = widget.modelsCallback!();
                        for (var m in models!) {
                          if (m[2] == modelName) {
                            modelFound = true;
                            break;
                          }
                        }
                      }
                      setState(() {
                        models = widget.modelsCallback!();
                        _isLoading = false;
                      });
                    }

                    Navigator.of(context).pop();
                    _modelNameController.clear();
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator() // Show loading indicator
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteModelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Model'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Are you sure you want to delete this model?'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    models = widget.modelsCallback!();
                    String modelName = models![_selectedItemIndex][2];
                    if (_selectedItemIndex != -1) {
                      await widget.postgresService
                          ?.deleteModel(models![_selectedItemIndex][2]);
                    }
                    bool isDeleted = false;
                    while (true) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      models = widget.modelsCallback!();
                      isDeleted = true;
                      for (var m in models!) {
                        if (m[2] == modelName) {
                          isDeleted = false;
                        }
                      }
                      if (isDeleted) {
                        break;
                      }
                    }
                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.of(context).pop();
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator() // Show loading indicator
                      : const Text('Delete'),
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
                physics: const ClampingScrollPhysics(),
                itemCount: widget.modelsCallback!().length,
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 0, color: Colors.transparent);
                },
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(
                        '${widget.modelsCallback!()[index][2]}   (${widget.modelsCallback!()[index][3]})'),
                    tileColor: _selectedItemIndex == index
                        ? Colors.deepPurpleAccent.withOpacity(0.3)
                        : null,
                    onTap: () {
                      setState(() {
                        if (_selectedItemIndex == index) {
                          _currentModelIndex = _selectedItemIndex;
                          widget.onSelectedModel!(_selectedItemIndex);
                          _isVisible = false;
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 35),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showCreateNewModelDialog();
                      },
                      child: const Text('Create new model'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.modelsCallback!().isEmpty) {
                          return;
                        }
                        _showDeleteModelDialog();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Visibility(
          //   visible: _isLoading,
          //   child: LinearProgressIndicator(),
          // ),
        ],
      ),
    );
  }
}
