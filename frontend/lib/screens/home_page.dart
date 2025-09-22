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
      backgroundColor: const Color(0xFFF0F4FD), // A soft, light background
      appBar: AppBar(
        title: const Text(
          'SafeConnect',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333D55)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Color(0xFF8995C2)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserProfilePage())),
            tooltip: 'User Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // A friendly illustration or icon to welcome the user.
              const Icon(Icons.security, color: Color(0xFF4A6CFF), size: 100),
              const SizedBox(height: 30),
              const Text(
                'Stay Safe & Connected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF333D55),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your all-in-one tool for network security and performance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const Spacer(),
              _FeatureBlob(
                icon: Icons.radar,
                label: "Wi-Fi Analyzer",
                color: const Color(0xFF4A6CFF),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WifiScanPage())),
              ),
              const SizedBox(height: 20),
              _FeatureBlob(
                icon: Icons.speed_outlined,
                label: "Speed Test",
                color: const Color(0xFF3CD3A4),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpeedTestPage())),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// A custom widget for the playful, blob-like feature buttons.
class _FeatureBlob extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FeatureBlob({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  __FeatureBlobState createState() => __FeatureBlobState();
}

class __FeatureBlobState extends State<_FeatureBlob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  
  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

