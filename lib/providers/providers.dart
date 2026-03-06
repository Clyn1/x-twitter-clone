// lib/providers/providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/profile_setup_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import 'auth_notifier.dart';
import 'profile_setup_notifier.dart';
import 'post_notifier.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// ── User / Profile ────────────────────────────────────────────────────────────

final userServiceProvider = Provider<UserService>((ref) => UserService());

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamUser(uid);
});

final profileSetupNotifierProvider =
    StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref) {
  return ProfileSetupNotifier(
    ref.watch(userServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// ── Posts ─────────────────────────────────────────────────────────────────────

final postServiceProvider = Provider<PostService>((ref) => PostService());

/// Global "For You" feed stream
final globalFeedProvider = StreamProvider<List<dynamic>>((ref) {
  return ref.watch(postServiceProvider).streamGlobalFeed();
});

/// Following feed stream
final followingFeedProvider = StreamProvider<List<dynamic>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(postServiceProvider).streamFollowingFeed(uid);
});

/// Create post state
final createPostProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier(ref.watch(postServiceProvider));
});

/// Per-user like state manager
final feedLikesProvider =
    StateNotifierProvider<FeedNotifier, Map<String, bool>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return FeedNotifier(ref.watch(postServiceProvider), uid);
});