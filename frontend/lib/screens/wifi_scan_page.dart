// lib/screens/wifi_scan_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({Key? key}) : super(key: key);
  @override
  _WifiScanPageState createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  List<WiFiAccessPoint> _suspiciousAPs = [];
  bool _isScanning = false;

  Future<void> _startScan() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wi-Fi scanning only supported on Android.")));
      return;
    }

    var status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission is required for scanning.")));
      return;
    }

    setState(() => _isScanning = true);
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();
      _processResults(results);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot start scan: $canScan")));
    }
    if (mounted) setState(() => _isScanning = false);
  }

  void _processResults(List<WiFiAccessPoint> results) {
    Map<String, List<WiFiAccessPoint>> ssidGroups = {};
    for (var ap in results) {
      if (ap.ssid.isNotEmpty) {
        (ssidGroups[ap.ssid] ??= []).add(ap);
      }
    }

    List<WiFiAccessPoint> suspicious = [];
    // Rule 1: Flag open networks (no security)
    suspicious.addAll(results.where((ap) => !ap.capabilities.contains('WPA') && !ap.capabilities.contains('WEP')));
    
    // Rule 2: Flag networks with duplicate SSIDs (potential evil twin)
    ssidGroups.forEach((ssid, apList) {
      if (apList.length > 1) {
        suspicious.addAll(apList);
      }
    });

    // Remove duplicates from the suspicious list
    final uniqueBssids = <String>{};
    _suspiciousAPs = suspicious.where((ap) => uniqueBssids.add(ap.bssid)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wi-Fi Scan Results")),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        child: _isScanning ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.refresh),
      ),
      body: _suspiciousAPs.isEmpty && !_isScanning
          ? const Center(child: Text("No suspicious networks found. Tap scan to start."))
          : ListView.builder(
              itemCount: _suspiciousAPs.length,
              itemBuilder: (context, index) {
                final ap = _suspiciousAPs[index];
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network'),
                  subtitle: Text("BSSID: ${ap.bssid}\nSecurity: ${ap.capabilities.contains('WPA') || ap.capabilities.contains('WEP') ? 'Protected' : 'Open'}"),
                  trailing: Text("${ap.level} dBm"),
                );
              },
            ),
    );
  }
}

