import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xff1d3298),
      ),
      backgroundColor: const Color(0xFF222240),
      body: const Center(
        child: Text(
          'This is the Profile Screen.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
