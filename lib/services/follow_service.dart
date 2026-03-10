// lib/services/follow_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _followId(String followerId, String followingId) =>
      '${followerId}_$followingId';

  // ── Follow / Unfollow ─────────────────────────────────────────────────────

  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    final batch = _db.batch();

    // Create follow doc
    batch.set(
      _db.collection('follows').doc(_followId(followerId, followingId)),
      {
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // Increment counts
    batch.update(_db.collection('users').doc(followerId),
        {'followingCount': FieldValue.increment(1)});
    batch.update(_db.collection('users').doc(followingId),
        {'followersCount': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    final batch = _db.batch();

    batch.delete(
      _db.collection('follows').doc(_followId(followerId, followingId)),
    );

    batch.update(_db.collection('users').doc(followerId),
        {'followingCount': FieldValue.increment(-1)});
    batch.update(_db.collection('users').doc(followingId),
        {'followersCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  // ── Check status ──────────────────────────────────────────────────────────

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final doc = await _db
        .collection('follows')
        .doc(_followId(followerId, followingId))
        .get();
    return doc.exists;
  }

  Stream<bool> streamIsFollowing({
    required String followerId,
    required String followingId,
  }) {
    return _db
        .collection('follows')
        .doc(_followId(followerId, followingId))
        .snapshots()
        .map((doc) => doc.exists);
  }
}
