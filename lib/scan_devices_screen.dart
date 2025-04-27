import 'package:flutter/material.dart';
import 'package:flutter_ble/charger_carousel.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_control_screen.dart';
import 'profile_screen.dart';
import 'resume_start_screen.dart';

class ScanDevicesScreen extends StatefulWidget {
  @override
  _ScanDevicesScreenState createState() => _ScanDevicesScreenState();
}

class _ScanDevicesScreenState extends State<ScanDevicesScreen> {
  List<BluetoothDevice> devicesList = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartScan();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    var status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      bool isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        try {
          await FlutterBluePlus.turnOn();
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth is required to scan devices.')),
          );
          return;
        }
      }
      _startScan();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _startScan() {
    devicesList.clear();
    setState(() => isScanning = true);

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult result in results) {
        final name = result.device.advName;
        if (name.isNotEmpty &&
            name.contains("A1 ") && // Filter: show only A1 devices
            !devicesList.any((d) => d.remoteId == result.device.remoteId)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
      setState(() => isScanning = false);
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      FlutterBluePlus.stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeviceControlScreen(device: device)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SizedBox(
        width: 250,
        child: Drawer(
          backgroundColor: const Color(0xff3839b1),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xff152266)),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.white),
                title: const Text('Resume Start', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ResumeStartScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Scan Charger Identifier", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff1d3298),
        actions: const [

        ],
      ),
      backgroundColor: const Color(0xFF222240),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Scharge Chargers", style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          const ChargerCarousel(),
          isScanning
              ? const Center(child: CircularProgressIndicator())
              : devicesList.isEmpty
              ? const Center(child: Text("No A1 devices found.", style: TextStyle(color: Colors.white)))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "A1 Basics",
                  style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 230.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return Container(
                      width: 300.0,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xff5d98a8),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.ev_station_rounded,
                                color: Colors.amber, size: 40.0),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.advName,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16.0)),
                                  const SizedBox(height: 5.0),
                                  Text(device.remoteId.toString(),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12.0)),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
                                      onPressed: () => _connectToDevice(device),
                                      child: const Text("Connect"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
