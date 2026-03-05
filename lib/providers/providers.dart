// lib/providers/providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/profile_setup_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth_notifier.dart';
import 'profile_setup_notifier.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

/// Provides the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Streams the Firebase auth state (User? — null means logged out)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Manages transient UI auth state (loading / error for login & register forms)
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// ── User / Profile ────────────────────────────────────────────────────────────

/// Provides the UserService instance
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Streams the current user's Firestore document in real time.
/// Returns null if the document doesn't exist (profile not set up yet).
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamUser(uid);
});

/// Manages profile setup form state (loading / error / success)
final profileSetupNotifierProvider =
    StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref) {
  return ProfileSetupNotifier(
    ref.watch(userServiceProvider),
    ref.watch(authServiceProvider),
  );
});