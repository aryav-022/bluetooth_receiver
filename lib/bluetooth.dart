import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothReceiver extends StatefulWidget {
  const BluetoothReceiver({super.key});

  @override
  _BluetoothReceiverState createState() => _BluetoothReceiverState();
}

class _BluetoothReceiverState extends State<BluetoothReceiver> {
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;

  void startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.advName == 'raspberrypi') {
          setState(() {
            targetDevice = r.device;
          });
          FlutterBluePlus.stopScan();
          connectToDevice();
          break;
        }
      }
    });
  }

  Future<void> connectToDevice() async {
    if (targetDevice == null) return;

    await targetDevice!.connect();
    discoverServices();
  }

  void discoverServices() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          setState(() {
            targetCharacteristic = characteristic;
          });
          await characteristic.setNotifyValue(
              true); // Ensure this is awaited for flutter_blue_plus
          characteristic.lastValueStream.listen((value) {
            processData(value); // Process incoming data here
          });
        }
      }
    }
  }

  void processData(List<int> data) {
    String receivedText = String.fromCharCodes(data);
    print("Received data: $receivedText");
    // Handle the received text (e.g., display on screen)
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Bluetooth Receiver")),
        body: Center(
          child: ElevatedButton(
            onPressed: startScan,
            child: const Text("Scan for Raspberry Pi"),
          ),
        ),
      ),
    );
  }
}

void main() => runApp(const BluetoothReceiver());
