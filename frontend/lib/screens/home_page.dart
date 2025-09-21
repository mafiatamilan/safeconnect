// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/screens/speed_test_page.dart';
import 'package:frontend/screens/user_profile_page.dart';
import 'package:frontend/screens/wifi_scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserProfilePage())),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeatureButton(
                icon: Icons.wifi_tethering,
                label: "Scan Wi-Fi",
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WifiScanPage())),
              ),
              const SizedBox(height: 30),
              _FeatureButton(
                icon: Icons.speed,
                label: "Run Speed Test",
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpeedTestPage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FeatureButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}

