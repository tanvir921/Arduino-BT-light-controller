import 'dart:async';
import 'package:arduino_bluetooth/bluetooth_device_list_entry.dart';
import 'package:arduino_bluetooth/discovery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'chat_page.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPage createState() => _MainPage();
}

enum _DeviceAvailability {
  // ignore: unused_field
  no,
  // ignore: unused_field
  maybe,
  yes,
}

class _DeviceWithAvailability {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int? rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _MainPage extends State<MainPage> {
  List<_DeviceWithAvailability> devices =
      List<_DeviceWithAvailability>.empty(growable: true);

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  Timer? _discoverableTimeoutTimer;



  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map(
              (device) => _DeviceWithAvailability(
                device,
                _DeviceAvailability.yes,
              ),
            )
            .toList();
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {});
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {});
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
      });
    });
  }

  //bool vsbl = false;

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDeviceListEntry> list = devices
        .map((device) => BluetoothDeviceListEntry(
              device: device.device,
              rssi: device.rssi,
              enabled: device.availability == _DeviceAvailability.yes,
              onTap: () {
                _startChat(context, device.device);
                //Navigator.of(context).pop(device.device);
              },
            ))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Light Controller'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final BluetoothDevice? selectedDevice =
              await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return DiscoveryPage();
              },
            ),
          );

          if (selectedDevice != null) {
            print('Discovery -> selected ' + selectedDevice.address);
          } else {
            print('Discovery -> no device selected');
          }
        },
        child: const Center(
          child: Icon(Icons.add),
        ),
      ),
      body: Column(
        children: <Widget>[
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Bluetooth'),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              // Do the request and update with the true value then
              future() async {
                // async lambda seems to not working
                if (value) {
                  await FlutterBluetoothSerial.instance.requestEnable();
                } else {
                  await FlutterBluetoothSerial.instance.requestDisable();
                }
              }

              // setState(() {
              //   _bluetoothState.isEnabled ? vsbl = true : false;
              // });

              future().then((_) {
                setState(() async {
                  final BluetoothDevice? selectedDevice =
                      await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        return const MainPage();
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Discovery -> selected ' + selectedDevice.address);
                  } else {
                    print('Discovery -> no device selected');
                  }
                });
              });
            },
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('PAIRED DEVICES:'),

                  Center(
                    child: _bluetoothState.isEnabled
                        ? ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: list,
                          )
                        : const Column(
                            children: [
                              SizedBox(
                                height: 300,
                              ),
                              Text(
                                  'Please enable bluetooth to see paired devices :)'),
                            ],
                          ),
                  ),
                  // Visibility(
                  //   visible: _bluetoothState.isEnabled,
                  //   child: ListView(
                  //     shrinkWrap: true,
                  //     physics: NeverScrollableScrollPhysics(),
                  //     children: list,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

 
}
