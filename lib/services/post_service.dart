// lib/services/post_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<void> createPost({
    required String uid,
    required String username,
    required String displayName,
    String? photoUrl,
    required String content,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    // 1. Create post doc to get an ID
    final docRef = _posts.doc();

    // 2. Upload image if provided
    String? imageUrl;
    if (imageBytes != null && imageMimeType != null) {
      final ext = imageMimeType.contains('png') ? 'png' : 'jpg';
      final ref = _storage.ref().child('post_images/${docRef.id}.$ext');
      final task = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: imageMimeType),
      );
      imageUrl = await task.ref.getDownloadURL();
    }

    // 3. Save post
    final post = PostModel(
      id: docRef.id,
      uid: uid,
      username: username,
      displayName: displayName,
      photoUrl: photoUrl,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toMap());
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Global feed — all posts, newest first
  Stream<List<PostModel>> streamGlobalFeed() {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  /// Following feed — posts from users the current user follows
  Stream<List<PostModel>> streamFollowingFeed(String currentUid) {
    return _db
        .collection('follows')
        .where('followerId', isEqualTo: currentUid)
        .snapshots()
        .asyncMap((followSnap) async {
      final followingIds =
          followSnap.docs.map((d) => d['followingId'] as String).toList();

      if (followingIds.isEmpty) return <PostModel>[];

      // Firestore whereIn supports up to 30 values
      final chunks = <List<String>>[];
      for (var i = 0; i < followingIds.length; i += 30) {
        chunks.add(followingIds.sublist(
            i, i + 30 > followingIds.length ? followingIds.length : i + 30));
      }

      final results = await Future.wait(chunks.map((chunk) => _posts
          .where('uid', whereIn: chunk)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()));

      final allPosts =
          results.expand((snap) => snap.docs.map(PostModel.fromDoc)).toList();
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allPosts;
    });
  }

  // ── Likes ───────────────────────────────────────────────────────────────────

  Future<bool> isLiked(String postId, String uid) async {
    final doc =
        await _posts.doc(postId).collection('likes').doc(uid).get();
    return doc.exists;
  }

  Future<void> toggleLike({
    required String postId,
    required String uid,
    required bool currentlyLiked,
  }) async {
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);

    await _db.runTransaction((tx) async {
      if (currentlyLiked) {
        tx.delete(likeRef);
        tx.update(postRef, {'likesCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'uid': uid, 'likedAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likesCount': FieldValue.increment(1)});
      }
    });
  }

  /// Fetch like status for a list of post IDs
  Future<Map<String, bool>> getLikeStatuses(
      List<String> postIds, String uid) async {
    final results = await Future.wait(
      postIds.map((id) => _posts.doc(id).collection('likes').doc(uid).get()),
    );
    return {
      for (var i = 0; i < postIds.length; i++)
        postIds[i]: results[i].exists,
    };
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }
}