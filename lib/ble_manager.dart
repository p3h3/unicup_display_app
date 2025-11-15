import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BleManager {
  final FlutterReactiveBle _ble;

  // for scanning
  final List<DiscoveredDevice> _devices = [];
  final _scanController = StreamController<List<DiscoveredDevice>>.broadcast();
  Stream<List<DiscoveredDevice>> get scanResults => _scanController.stream;

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  
  final Map<int, StreamController<List<List<int>>>> _subscriptionControllers = {};

  final Map<int, List<List<int>>> _notificationBuffer = {};
  final Map<int, int> _notificationBufferLastUpdate = {};

  // general for connection
  String? _deviceId;
  bool get isConnected => _deviceId != null;
  String? get deviceId => _deviceId;

  var currentMTU = 20;

  final List<Map<String, Uuid>> vcuBLECharacteristicIds =  [
    // Brightness control
    {
      'serviceId': Uuid.parse("c1911000-51fd-402c-a17a-c09a33fd9c81"),
      'characteristicId': Uuid.parse("c1911001-51fd-402c-a17a-c09a33fd9c81")
    },
    // Bitmap animation
    {
      'serviceId': Uuid.parse("c1911000-51fd-402c-a17a-c09a33fd9c81"),
      'characteristicId': Uuid.parse("c1911002-51fd-402c-a17a-c09a33fd9c81")
    },
    // Bitmap static pic
    {
      'serviceId': Uuid.parse("c1911000-51fd-402c-a17a-c09a33fd9c81"),
      'characteristicId': Uuid.parse("c1911003-51fd-402c-a17a-c09a33fd9c81")
    },
    // Bitmap chunk
    {
      'serviceId': Uuid.parse("c1911000-51fd-402c-a17a-c09a33fd9c81"),
      'characteristicId': Uuid.parse("c1911004-51fd-402c-a17a-c09a33fd9c81")
    },
  ];

  BleManager(this._ble);

  void setDeviceId(String id) {
    _deviceId = id;
  }

  QualifiedCharacteristic getCharacteristic(int index) {
    final charInfo = vcuBLECharacteristicIds[index];
    return QualifiedCharacteristic(
      serviceId: charInfo['serviceId']!,
      characteristicId: charInfo['characteristicId']!,
      deviceId: _deviceId!,
    );
  }

  Future<List<int>> read(int characteristicIndex) async {
    final char = getCharacteristic(characteristicIndex);
    return await _ble.readCharacteristic(char);
  }

  Future<void> write(int characteristicIndex, List<int> data) async {
    final char = getCharacteristic(characteristicIndex);
    await _ble.writeCharacteristicWithResponse(char, value: data);
  }

  Future<void> writeWithoutResponse(int characteristicIndex, List<int> data) async {
    final char = getCharacteristic(characteristicIndex);
    await _ble.writeCharacteristicWithoutResponse(char, value: data);
  }
  
  Stream<List<List<int>>> subscribe(int characteristicIndex) {
    StreamController<List<List<int>>> controller =
        StreamController<List<List<int>>>.broadcast();
    _subscriptionControllers[characteristicIndex] = controller;


    final char = getCharacteristic(characteristicIndex);
    _ble.subscribeToCharacteristic(char).listen((data) {
      if(_notificationBuffer.containsKey(characteristicIndex)){
          List<List<int>> currentBuffer = _notificationBuffer[characteristicIndex]!;
          currentBuffer.add(data);
        }else{
          _notificationBuffer[characteristicIndex] = [data];
        }

        if(_subscriptionControllers.containsKey(characteristicIndex)){
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final lastUpdate = _notificationBufferLastUpdate[characteristicIndex];
          if (lastUpdate == null || lastUpdate < (timestamp - 33)) {
            _subscriptionControllers[characteristicIndex]!.sink.add(_notificationBuffer[characteristicIndex]!);

            _notificationBuffer[characteristicIndex] = [];
            _notificationBufferLastUpdate[characteristicIndex] = timestamp;
          }
        }
    });


    return controller.stream;
  }


// connection and scanning
void startScan() {
    _devices.clear();
    _scanSub?.cancel();

    _scanSub = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      final data = device.manufacturerData;
      final id = data.length >= 2 ? (data[1] << 8 | data[0]) : null;

      if (device.name.contains("led") && !_devices.any((d) => d.id == device.id)) {
        _devices.add(device);
        _scanController.add(List.from(_devices));
      }
    });
  }

  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }


  Future<void> connectToDevice({
    required String deviceId,
    required void Function() onConnected,
    required void Function(Object error) onError,
    void Function()? onDisconnected,
  }) async {
    stopScan(); // Stop scanning before connecting

    _connectionSub?.cancel();

    _connectionSub = _ble.connectToDevice(id: deviceId).listen(
      (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            _deviceId = deviceId;

            currentMTU = await _ble.requestMtu(
              deviceId: deviceId,
              mtu: 517,
            );

            Fluttertoast.showToast(
              msg: "MTU: " + currentMTU.toString(),
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
              timeInSecForIosWeb: 5,
              backgroundColor: Colors.white,
              textColor: Colors.green,
              fontSize: 15.0,
            );
            
            await Future.delayed(const Duration(seconds: 1)); // professional 1s wait because BLE sucks
            onConnected();
            break;
          case DeviceConnectionState.disconnected:
            _deviceId = null;
            onDisconnected?.call();
            break;
          default:
            break;
        }
      },
      onError: (e) {
        _deviceId = null;
        onError(e);
      },
    );
  }


  // the classic
  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _scanController.close();
  }

}