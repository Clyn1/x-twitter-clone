// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../providers/providers.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final uid = user?.uid ?? '';

    final screens = [
      _FeedPage(tabController: _tabController, currentUid: uid),
      const CreatePostScreen(),
      _ProfilePage(uid: uid),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Feed Page ─────────────────────────────────────────────────────────────────

class _FeedPage extends ConsumerWidget {
  final TabController tabController;
  final String currentUid;

  const _FeedPage({
    required this.tabController,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalFeed = ref.watch(globalFeedProvider);
    final followingFeed = ref.watch(followingFeedProvider);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          backgroundColor: const Color(0xFF0A0A14).withOpacity(0.95),
          elevation: 0,
          floating: true,
          snap: true,
          pinned: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9BF0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flutter_dash,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: tabController,
            indicatorColor: const Color(0xFF1D9BF0),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'For You'),
              Tab(text: 'Following'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: tabController,
        children: [
          // For You tab
          _FeedList(
            feedAsync: globalFeed,
            currentUid: currentUid,
            emptyMessage: 'No posts yet.\nBe the first to post!',
          ),
          // Following tab
          _FeedList(
            feedAsync: followingFeed,
            currentUid: currentUid,
            emptyMessage: 'Follow people to see\ntheir posts here.',
          ),
        ],
      ),
    );
  }
}

class _FeedList extends ConsumerWidget {
  final AsyncValue<List<dynamic>> feedAsync;
  final String currentUid;
  final String emptyMessage;

  const _FeedList({
    required this.feedAsync,
    required this.currentUid,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return feedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1D9BF0),
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error loading feed',
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ),
      data: (posts) {
        final typedPosts = posts.cast<PostModel>();

        // Load like statuses whenever posts change
        if (typedPosts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(feedLikesProvider.notifier).loadLikes(typedPosts);
          });
        }

        if (typedPosts.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: typedPosts.length,
          itemBuilder: (context, index) => PostCard(
            post: typedPosts[index],
            currentUid: currentUid,
          ),
        );
      },
    );
  }
}

// ── Profile Page (placeholder) ────────────────────────────────────────────────

class _ProfilePage extends ConsumerWidget {
  final String uid;

  const _ProfilePage({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        title: Text(
          user?.displayName ?? 'Profile',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: Colors.white.withOpacity(0.6), size: 20),
            onPressed: () => ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9BF0)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover
                  Container(
                    height: 120,
                    color: const Color(0xFF1D9BF0).withOpacity(0.15),
                  ),

                  // Avatar + follow button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -32),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1D9BF0).withOpacity(0.2),
                              border: Border.all(
                                  color: const Color(0xFF0A0A14), width: 3),
                              image: user.photoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.photoUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: user.photoUrl == null
                                ? Center(
                                    child: Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Color(0xFF1D9BF0),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name + username
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('@${user.username}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 14)),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(user.bio,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  height: 1.4)),
                        ],
                        const SizedBox(height: 14),

                        // Stats
                        Row(children: [
                          _Stat(
                              count: user.followingCount,
                              label: 'Following'),
                          const SizedBox(width: 20),
                          _Stat(
                              count: user.followersCount,
                              label: 'Followers'),
                        ]),
                        const SizedBox(height: 16),
                        Divider(
                            color: Colors.white.withOpacity(0.07),
                            height: 1),
                      ],
                    ),
                  ),

                  // Posts tab placeholder
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Your posts will appear here',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;

  const _Stat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        count.toString(),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 14)),
    ]);
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.add_box_rounded,
                outlinedIcon: Icons.add_box_outlined,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outline_rounded,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: Icon(
            isActive ? icon : outlinedIcon,
            color: isActive ? Colors.white : Colors.white38,
            size: 26,
          ),
        ),
      ),
    );
  }
}
