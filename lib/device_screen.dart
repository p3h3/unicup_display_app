import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../ble_manager.dart';

import 'package:fluttertoast/fluttertoast.dart';

class DeviceScreen extends StatefulWidget {
  final BleManager bleManager;

  const DeviceScreen({super.key, required this.bleManager});

  @override
  DeviceScreenState createState() => DeviceScreenState();
}

class DeviceScreenState extends State<DeviceScreen> {
  late StreamSubscription<List<DiscoveredDevice>> _bleScanStreamSub;

  List<DiscoveredDevice> _bleDevices = [];

  bool _isConnecting = false;
  String _isConnectingText = "";

  @override
  void initState() {
    super.initState();

    _checkAndRequestBLEPermissions().then((granted) {
      if (granted) {
        widget.bleManager.startScan();
        _bleScanStreamSub = widget.bleManager.scanResults.listen((devices) {
          setState(() {
            _bleDevices = devices;
          });
        });
      } else {
        Fluttertoast.showToast(
          msg: "BLE permissions not granted.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 5,
          backgroundColor: Colors.white,
          textColor: Colors.red,
          fontSize: 30.0,
        );
      }
    });

  }

  Future<void> _connectBLE(String deviceId) async {
    setState(() {
      _isConnecting = true;
      _isConnectingText = "Connecting Bluetooth...";
    });

    await widget.bleManager.connectToDevice(
      deviceId: deviceId,
      onConnected: () async {
        setState(() {
          _isConnecting = false;
        });
        Navigator.of(context).pop(deviceId);
      },
      onError: (error) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("BLE Connection failed: $error")),
        );
      },
      onDisconnected: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Disconnected BLE from $deviceId")),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.bleManager.stopScan();
    _bleScanStreamSub.cancel();
    super.dispose();
  }

  Future<bool> _checkAndRequestBLEPermissions() async {
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return status.values.every((s) => s == PermissionStatus.granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: const Text("Select a Device")),
  body: Stack(
    children: [
      Column(
        children: [
          // First Half
          Expanded(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Available via BLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _bleDevices.length,
                    itemBuilder: (context, index) {
                      final device = _bleDevices[index];
                      return ListTile(
                        title: Text(device.name.isNotEmpty ? device.name : "Unknown"),
                        subtitle: Text(device.id),
                        onTap: () => _connectBLE(device.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (_isConnecting)
        Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16), // spacing between the indicator and text
                Text(
                  _isConnectingText,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
    ],
  ),
);

  }
}
