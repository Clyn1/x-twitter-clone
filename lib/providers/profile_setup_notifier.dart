// lib/providers/profile_setup_notifier.dart

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../models/profile_setup_state.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  final UserService _userService;
  final AuthService _authService;

  ProfileSetupNotifier(this._userService, this._authService)
      : super(ProfileSetupState.initial);

  Future<void> saveProfile({
    required String username,
    required String displayName,
    required String bio,
    Uint8List? photoBytes,
    String? photoMimeType,
  }) async {
    final uid = _authService.currentUser?.uid;
    final email = _authService.currentUser?.email;

    if (uid == null || email == null) {
      state = state.copyWith(
        status: ProfileSetupStatus.error,
        errorMessage: 'Not authenticated. Please sign in again.',
      );
      return;
    }

    state = state.copyWith(status: ProfileSetupStatus.loading);

    try {
      // 1. Check username availability
      final taken = await _userService.isUsernameTaken(username);
      if (taken) {
        state = state.copyWith(
          status: ProfileSetupStatus.error,
          errorMessage: 'That username is already taken.',
        );
        return;
      }

      // 2. Create the Firestore user document
      final user = UserModel(
        uid: uid,
        email: email,
        username: username.toLowerCase(),
        displayName: displayName,
        bio: bio,
        createdAt: DateTime.now(),
      );
      await _userService.createUser(user);

      // 3. Upload profile photo if provided
      if (photoBytes != null && photoMimeType != null) {
        await _userService.uploadProfilePhoto(
          uid: uid,
          bytes: photoBytes,
          mimeType: photoMimeType,
        );
      }

      state = state.copyWith(status: ProfileSetupStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ProfileSetupStatus.error,
        errorMessage: _parseError(e.toString()),
      );
    }
  }

  void clearError() {
    if (state.isError) state = ProfileSetupState.initial;
  }

  String _parseError(String raw) {
    if (raw.contains('permission-denied')) {
      return 'Permission denied. Check Firestore rules.';
    }
    if (raw.contains('network')) return 'Network error. Check your connection.';
    return 'Something went wrong. Please try again.';
  }
}