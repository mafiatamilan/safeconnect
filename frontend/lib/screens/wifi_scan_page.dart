// lib/screens/wifi_scan_page.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

// Enum to define the security status of a network.
enum WifiSecurityStatus { safe, suspiciousOpen, suspiciousEvilTwin }

// A custom class to hold the AP and its classified security status.
class ClassifiedAP {
  final WiFiAccessPoint ap;
  final WifiSecurityStatus status;
  final String reason;

  ClassifiedAP({required this.ap, required this.status, required this.reason});
}

class WifiScanPage extends StatefulWidget {
  const WifiScanPage({Key? key}) : super(key: key);
  @override
  _WifiScanPageState createState() => _WifiScanPageState();
}

class _WifiScanPageState extends State<WifiScanPage> {
  List<ClassifiedAP> _classifiedAPs = [];
  bool _isScanning = false;
  String _scanStatus = "Tap the scan button to analyze nearby networks.";

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      Permission.location.request();
    }
  }

  Future<void> _startScan() async {
    if (await Permission.location.isDenied || await Permission.location.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required to scan for Wi-Fi networks.")),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _classifiedAPs = [];
      _scanStatus = "Analyzing networks...";
    });

    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      if (mounted) setState(() {
        _isScanning = false;
        _scanStatus = "Cannot start scan: $canScan. Please ensure location services are enabled.";
      });
      return;
    }

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    if (mounted) _processResults(results);

    if (mounted) setState(() {
      _isScanning = false;
      if (_classifiedAPs.isEmpty) {
        _scanStatus = "Scan complete. No networks were found.";
      }
    });
  }

  void _processResults(List<WiFiAccessPoint> results) {
    final Map<String, List<WiFiAccessPoint>> ssidGroups = {};
    for (final ap in results) {
      if (ap.ssid.isNotEmpty) {
        (ssidGroups[ap.ssid] ??= []).add(ap);
      }
    }

    final List<ClassifiedAP> classifiedList = [];
    for (final ap in results) {
      final isSecure = ap.capabilities.contains('WPA') || ap.capabilities.contains('WEP');
      final isPotentialEvilTwin = (ssidGroups[ap.ssid]?.length ?? 0) > 1;

      if (isPotentialEvilTwin) {
        classifiedList.add(ClassifiedAP(ap: ap, status: WifiSecurityStatus.suspiciousEvilTwin, reason: "Potential Evil Twin"));
      } else if (!isSecure) {
        classifiedList.add(ClassifiedAP(ap: ap, status: WifiSecurityStatus.suspiciousOpen, reason: "Open Network"));
      } else {
        classifiedList.add(ClassifiedAP(ap: ap, status: WifiSecurityStatus.safe, reason: "Secured"));
      }
    }

    // Sort by status first (critical threats at the top), then by signal strength.
    classifiedList.sort((a, b) {
      int statusComparison = a.status.index.compareTo(b.status.index);
      if (statusComparison != 0) {
        return statusComparison;
      }
      return b.ap.level.compareTo(a.ap.level); // Stronger signals first
    });

    setState(() {
      _classifiedAPs = classifiedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2229), // Dark background
      appBar: AppBar(
        title: const Text("Wi-Fi Network Analyzer"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: const Color(0xFF4A6CFF),
        icon: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.radar, color: Colors.white),
        label: Text(_isScanning ? "Scanning..." : "Scan for Threats", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isScanning) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A6CFF)));
    }
    if (_classifiedAPs.isEmpty) {
      return _buildEmptyState();
    }
    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_find, color: Colors.grey[700], size: 80),
          const SizedBox(height: 24),
          Text(
            _scanStatus,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _classifiedAPs.length,
      itemBuilder: (context, index) {
        final classifiedAp = _classifiedAPs[index];
        return WifiNetworkCard(classifiedAp: classifiedAp);
      },
    );
  }
}

// A dedicated widget for displaying a single, beautifully designed Wi-Fi network card.
class WifiNetworkCard extends StatelessWidget {
  final ClassifiedAP classifiedAp;

  const WifiNetworkCard({Key? key, required this.classifiedAp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ap = classifiedAp.ap;
    final status = classifiedAp.status;

    Color color;
    IconData icon;
    String tagText;

    switch (status) {
      case WifiSecurityStatus.suspiciousEvilTwin:
        color = const Color(0xFFE53935); // Red
        icon = Icons.copy_all_outlined;
        tagText = "CRITICAL";
        break;
      case WifiSecurityStatus.suspiciousOpen:
        color = const Color(0xFFFFA000); // Orange
        icon = Icons.lock_open_rounded;
        tagText = "SUSPICIOUS";
        break;
      case WifiSecurityStatus.safe:
      default:
        color = const Color(0xFF43A047); // Green
        icon = Icons.check_circle_outline;
        tagText = "SAFE";
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ap.ssid.isNotEmpty ? ap.ssid : 'Hidden Network',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      tagText,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("BSSID: ${ap.bssid}", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  Text("${ap.level} dBm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8995C2))),
                ],
              ),
              if (status != WifiSecurityStatus.safe) ...[
                const SizedBox(height: 8),
                Text(
                  "Reason: ${classifiedAp.reason}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

