// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        title: const Text(
          'X Clone',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
            onPressed: () =>
                ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF1D9BF0), size: 64),
            const SizedBox(height: 20),
            const Text(
              'Logged in successfully!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}