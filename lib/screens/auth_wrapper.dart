// lib/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => _loadingScaffold(),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();

        // Authenticated — check if Firestore profile exists
        final userDoc = ref.watch(currentUserProvider);
        return userDoc.when(
          loading: () => _loadingScaffold(),
          error: (_, __) => const ProfileSetupScreen(),
          data: (userModel) {
            if (userModel == null) return const ProfileSetupScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }

  Widget _loadingScaffold() => const Scaffold(
        backgroundColor: Color(0xFF0A0A14),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1D9BF0),
            strokeWidth: 2,
          ),
        ),
      );
}