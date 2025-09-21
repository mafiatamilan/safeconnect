// lib/screens/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/auth_wrapper.dart';
import 'package:frontend/services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthService _authService = AuthService();
  Future<Map<String, dynamic>?>? _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = _authService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Could not load profile."));
          }
          final profile = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(leading: const Icon(Icons.person), title: Text("Username: ${profile['username'] ?? 'N/A'}")),
                ListTile(leading: const Icon(Icons.email), title: Text("Email: ${profile['email'] ?? 'N/A'}")),
                ListTile(leading: const Icon(Icons.star), title: Text("Subscription: ${profile['subscription_status'] ?? 'N/A'}")),
                ListTile(leading: const Icon(Icons.calendar_today), title: Text("Member Since: ${profile['member_since'] ?? 'N/A'}")),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

