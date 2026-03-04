// lib/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial);

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  Future<void> register({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.register(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  void clearError() {
    if (state.isError) state = AuthState.initial;
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password')) return 'Incorrect password. Please try again.';
    if (raw.contains('email-already-in-use')) return 'An account already exists for this email.';
    if (raw.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email address.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (raw.contains('network-request-failed')) return 'Network error. Check your connection.';
    return 'Something went wrong. Please try again.';
  }
}
