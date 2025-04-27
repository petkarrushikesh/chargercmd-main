import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'charging_battery_animation.dart'; // Import charging animation widget

class DeviceControlScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceControlScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _chargingControlChar;
  BluetoothCharacteristic? _textFileChar;
  String _textFileContent = '';
  bool _isCharging = false; // For charging animation

  final String targetServiceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String controlCharUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String textFileUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await widget.device.requestMtu(247);
    await widget.device.connect(autoConnect: false);
    await _discoverServices();
  }

  Future<void> _discoverServices() async {
    final services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == targetServiceUUID) {
        for (var char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == controlCharUUID) {
            _chargingControlChar = char;
          } else if (uuid == textFileUUID) {
            _textFileChar = char;
          }
        }
      }
    }
    setState(() {
      _services = services;
    });
  }

  Future<void> _sendChargingCommand(Map<String, dynamic> command) async {
    if (_chargingControlChar == null) {
      print("❌ Control characteristic not found");
      return;
    }

    final jsonString = jsonEncode(command);
    final bytes = utf8.encode(jsonString);

    try {
      await _chargingControlChar!.write(bytes, withoutResponse: false);
      print("✅ Sent: $jsonString");

      if (command["optype"] == 202) {
        setState(() {
          _isCharging = true; // Start animation
        });
        await Future.delayed(const Duration(seconds: 2)); // simulate charging time
        _readTextFile(); // Read file after starting
      } else if (command["optype"] == 203) {
        setState(() {
          _isCharging = false; // Stop animation
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sent: $jsonString")),
      );
    } catch (e) {
      print("❌ Write failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Write failed: $e")),
      );
    }
  }

  Future<void> _readTextFile() async {
    if (_textFileChar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Text file characteristic not found")),
      );
      return;
    }

    try {
      final value = await _textFileChar!.read();
      final decoded = utf8.decode(value);
      setState(() {
        _textFileContent = decoded;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error reading text file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
      ),
      body: _services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Device: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _sendChargingCommand({"optype": 202, "Status": "OK"}),
                  child: const Text("Start Charging"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _sendChargingCommand({"optype": 203}),
                  child: const Text("Stop Charging"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isCharging) ...[
              const ChargingBatteryAnimation(), // Battery animation
              const SizedBox(height: 20),
            ],
            if (_textFileContent.isNotEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Text File Content",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _readTextFile,  // <-- refresh on tap
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 300, // height for ListView
                        child: ListView.builder(
                          itemCount: _textFileContent.split('\n').length,
                          itemBuilder: (context, index) {
                            final line = _textFileContent.split('\n')[index];
                            return ListTile(
                              leading: const Icon(Icons.notes),
                              title: Text(line.trim()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }
}
