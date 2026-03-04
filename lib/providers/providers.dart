// lib/providers/providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import 'auth_notifier.dart';

/// Provides the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Streams the Firebase auth state (User? — null means logged out)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Manages transient UI auth state (loading / error for login & register forms)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});