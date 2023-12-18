import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:obd2_plugin/obd2_plugin.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<BluetoothDevice>? devices;
  BluetoothState? bluetoothState;
  BluetoothDevice? selectedDevice;
  bool areNotificationsEnabled = true;
  bool isLoading = true;
  bool isConnected = false;

  @override
  void dispose() {
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
    while (bluetoothState == BluetoothState.STATE_ON) {
      await Future.delayed(Duration(seconds: 1));
      if (!isConnected) {
        List<BluetoothDevice> pairedDevices =
            await FlutterBluetoothSerial.instance.getBondedDevices();
        setState(() {
          devices = pairedDevices;
          isLoading = false;
        });
      }
    }
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
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Language'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Implement action for language settings
                // For example: navigate to language selection screen
              },
            ),
            // Add more settings as needed
          ],
        ),
      ),
    );
  }
}
