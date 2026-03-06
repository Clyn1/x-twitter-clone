// lib/providers/post_notifier.dart

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

// ── Create Post State ─────────────────────────────────────────────────────────

enum CreatePostStatus { initial, loading, success, error }

class CreatePostState {
  final CreatePostStatus status;
  final String? errorMessage;

  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == CreatePostStatus.loading;
  bool get isSuccess => status == CreatePostStatus.success;
  bool get isError => status == CreatePostStatus.error;

  static const initial = CreatePostState();

  CreatePostState copyWith({
    CreatePostStatus? status,
    Object? errorMessage = _sentinel,
  }) =>
      CreatePostState(
        status: status ?? this.status,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}

const Object _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final PostService _postService;

  CreatePostNotifier(this._postService) : super(CreatePostState.initial);

  Future<void> createPost({
    required String uid,
    required String username,
    required String displayName,
    String? photoUrl,
    required String content,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    state = state.copyWith(status: CreatePostStatus.loading);
    try {
      await _postService.createPost(
        uid: uid,
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        content: content,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );
      state = state.copyWith(status: CreatePostStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: CreatePostStatus.error,
        errorMessage: 'Could not post. Please try again.',
      );
    }
  }

  void reset() => state = CreatePostState.initial;
}

// ── Feed Like State ───────────────────────────────────────────────────────────

class FeedNotifier extends StateNotifier<Map<String, bool>> {
  final PostService _postService;
  final String _uid;

  FeedNotifier(this._postService, this._uid) : super({});

  Future<void> loadLikes(List<PostModel> posts) async {
    if (posts.isEmpty) return;
    final ids = posts.map((p) => p.id).toList();
    final statuses = await _postService.getLikeStatuses(ids, _uid);
    state = {...state, ...statuses};
  }

  Future<void> toggleLike(String postId) async {
    final currentlyLiked = state[postId] ?? false;
    // Optimistic update
    state = {...state, postId: !currentlyLiked};
    try {
      await _postService.toggleLike(
        postId: postId,
        uid: _uid,
        currentlyLiked: currentlyLiked,
      );
    } catch (_) {
      // Revert on error
      state = {...state, postId: currentlyLiked};
    }
  }

  bool isLiked(String postId) => state[postId] ?? false;
}