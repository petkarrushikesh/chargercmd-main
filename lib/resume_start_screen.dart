import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ResumeStartScreen extends StatefulWidget {
  @override
  State<ResumeStartScreen> createState() => _ResumeStartScreenState();
}

class _ResumeStartScreenState extends State<ResumeStartScreen> {
  List<BluetoothDevice> scDevices = [];
  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;
  String status = "Idle";
  final Guid targetCharacteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26b2");

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    scDevices.clear();
    setState(() {
      isScanning = true;
      isConnected = false;
      connectedDevice = null;
      status = "Scanning for SC chargers...";
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        final name = result.device.advName;
        if (name.isNotEmpty &&
            (name.contains("SC101") || name.contains("SCA1") )&&
            !result.device.platformName.contains("A1_B") &&
            !scDevices.any((d) => d.remoteId == result.device.remoteId)) {
          setState(() {
            scDevices.add(result.device);
          });
        }
      }
      setState(() => isScanning = false);
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      status = "Connecting to ${device.advName}...";
    });

    try {
      await FlutterBluePlus.stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() {
        isConnecting = false;
        isConnected = true;
        connectedDevice = device;
        status = "Connected to ${device.advName}. Ready for Resume Start.";
      });
    } catch (e) {
      setState(() {
        isConnecting = false;
        status = "Connection failed: $e";
      });
    }
  }

  void _sendResumeStartCommand() async {
    if (connectedDevice == null) return;

    try {
      setState(() => status = "Discovering services...");
      List<BluetoothService> services = await connectedDevice!.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.uuid == targetCharacteristicUuid) {
            setState(() => status = "Sending Resume Start command...");
            const command = '{"optype":"85","mode":"1"}';
            await char.write(command.codeUnits, withoutResponse: false);
            setState(() => status = "Resume Start command sent successfully!");
            return;
          }
        }
      }

      setState(() => status = "Characteristic not found.");
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  void _disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        isConnected = false;
        status = "Disconnected from charger.";
      });
    }
  }

  @override
  void dispose() {
    _disconnectDevice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222240),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Resume Start - Chargers", style: TextStyle(color: Color(0xff1b1e1e))),
        backgroundColor: const Color(0xff6f7ce4),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.ev_station, size: 36, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            isScanning
                ? const CircularProgressIndicator()
                : !isConnected
                ? scDevices.isEmpty
                ? const Center(child: Text("No SC chargers found.", style: TextStyle(color: Colors.white)))
                : Expanded(
              child: ListView.builder(
                itemCount: scDevices.length,
                itemBuilder: (context, index) {
                  final device = scDevices[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth_connected, color: Colors.lightBlue),
                      title: Text(device.advName),
                      subtitle: Text(device.remoteId.toString()),
                      trailing: ElevatedButton(
                        onPressed: isConnecting ? null : () => _connectToDevice(device),
                        child: const Text("Connect"),
                      ),
                    ),
                  );
                },
              ),
            )
                : Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _sendResumeStartCommand,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Send Resume Start"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _disconnectDevice,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text("Disconnect"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
