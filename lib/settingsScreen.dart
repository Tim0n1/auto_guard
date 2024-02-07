import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:obd2_plugin/obd2_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'obd2.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SharedPreferences? prefs;
  List<BluetoothDevice>? devices;
  BluetoothState? bluetoothState;
  BluetoothDevice? selectedDevice;
  late Timer _pairedDevicesTimer;
  static const int _refreshInterval = 3;
  bool areNotificationsEnabled = true;
  bool isLoading = true;
  bool isConnected = false;
  bool isDisposed = false;
  int selectedSize = 0;
  int initialSelectedSize = 2;
  List<int> sizeOptions = [10, 20, 300, 1000];
  List<String> initialSelectedParameters = [];
  List<String> selectedParameters = [];
  List<String> ListOfParameters = StringJson().parametersTitles();

  @override
  void dispose() {
    _pairedDevicesTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        bluetoothState = state;
        print(state);
      });
    });
    getPairedDevices();
  }

  Future<void> getPairedDevices() async {
    bluetoothState = await FlutterBluetoothSerial.instance.state;
    print(bluetoothState == BluetoothState.STATE_ON);
    _pairedDevicesTimer = Timer.periodic(Duration(seconds: _refreshInterval),
        (Timer timer) async {
      if (bluetoothState == BluetoothState.STATE_ON) {
        if (!isConnected) {
          List<BluetoothDevice> pairedDevices =
              await FlutterBluetoothSerial.instance.getBondedDevices();
          setState(() {
            devices = pairedDevices;
            isLoading = false;
          });
        }
      }
    });
  }

  Future<void> closeConnectedDevice() async {
    List<BluetoothDevice> devices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    for (var i = 0; i < devices.length; i++) {
      if (devices[i].isConnected) {
        BluetoothConnection.toAddress(devices[i].address).then((connection) {
          connection.close();
        });
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice? device) async {
    setState(() {
      isLoading = true;
    });

    if (device != null) {
      try {
        await closeConnectedDevice();
        // Connect to the selected device
        BluetoothConnection connection =
            await BluetoothConnection.toAddress(device.address);

        // Do something with the connection (e.g., read/write data)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          isConnected = true;
          isLoading = false;
        });

        print("Connected ${device.name}");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Can\'t connect to ${device.name}',
                selectionColor: Colors.red),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          isLoading = false;
          isConnected = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
        isConnected = false;
      });
      print('No selected device');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Notifications'),
              trailing: Switch(
                value: areNotificationsEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    areNotificationsEnabled = newValue;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Bluetooth connection'),
              trailing: isLoading
                  ? const CircularProgressIndicator()
                  : DropdownButton<BluetoothDevice>(
                      value: selectedDevice,
                      hint: const Text('Select Device'),
                      onChanged: (BluetoothDevice? newValue) {
                        setState(() {
                          selectedDevice = newValue;
                        });
                        connectToDevice(selectedDevice);
                      },
                      items: devices?.map((BluetoothDevice device) {
                        return DropdownMenuItem<BluetoothDevice>(
                          value: device,
                          child: Text(device.name!),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Model Settings',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('Parameters'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                prefs = await SharedPreferences.getInstance();
                initialSelectedParameters =
                    prefs?.getStringList('parameters') ?? [];
                _showParametersDialog(initialSelectedParameters);
              },
            ),
            ListTile(
              title: const Text('Size'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                prefs = await SharedPreferences.getInstance();
                initialSelectedSize = prefs?.getInt('size') ?? 2;
                print('initialParameter: $initialSelectedParameters');
                print(initialSelectedSize);
                _showSizeDialog(initialSelectedSize);
              },
            ),
            ListTile(
              title: const Text('Threshold'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),

            const SizedBox(height: 15),
            const Text(
              'Other Settings',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            ListTile(
              title: const Text('Language'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Implement action for language settings
                // For example: navigate to language selection screen
              },
            ),
            ListTile(
              title: const Text('Help'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Implement action for language settings
                // For example: navigate to language selection screen
              },
            )
            // Add more settings as needed
          ],
        ),
      ),
    );
  }

  bool _isParametersInitialyOpened = true;
  void _showParametersDialog(List<String> initialSelectedParameters) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Select Parameters'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var parameter in ListOfParameters)
                      InkWell(
                        onTap: () {
                          selectedParameters = initialSelectedParameters;
                          setState(() {
                            if (selectedParameters.contains(parameter)) {
                              selectedParameters.remove(parameter);
                            } else {
                              selectedParameters.add(parameter);
                            }
                          });
                        },
                        child: ListTile(
                          title: Text(parameter),
                          leading: Checkbox(
                            value: _isParametersInitialyOpened
                                ? initialSelectedParameters.contains(parameter)
                                : selectedParameters.contains(parameter),
                            onChanged: (bool? value) {
                              _isParametersInitialyOpened = false;
                              setState(() {
                                //_isParametersInitialyOpened = false;
                                if (value != null) {
                                  if (value) {
                                    selectedParameters.add(parameter);
                                  } else {
                                    selectedParameters.remove(parameter);
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _isParametersInitialyOpened = true;
                    selectedParameters = initialSelectedParameters;
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs?.setStringList(
                        'parameters', selectedParameters);
                    print('Selected Parameters: $selectedParameters');
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSizeInitialyOpened = true;
  void _showSizeDialog(int initialSelectedSize) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Select Size'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: sizeOptions.map((int size) {
                  return RadioListTile<int>(
                    title: Text('$size'), // Convert int to String
                    value: size,
                    groupValue: _isSizeInitialyOpened
                        ? initialSelectedSize
                        : selectedSize,
                    onChanged: (int? value) {
                      setState(() {
                        print(_isSizeInitialyOpened);
                        _isSizeInitialyOpened = false;
                        selectedSize = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _isSizeInitialyOpened = true;
                    selectedSize = initialSelectedSize;
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (prefs == null) {
                      print('prefs is null');
                    }
                    await prefs?.setInt('size', selectedSize);
                    print('Selected Size: $selectedSize');
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
