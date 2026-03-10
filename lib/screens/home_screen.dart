// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../providers/providers.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

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
      ProfileScreen(uid: uid),
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

  const _FeedPage({required this.tabController, required this.currentUid});

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
          automaticallyImplyLeading: false,
          title: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9BF0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flutter_dash,
                  color: Colors.white, size: 18),
            ),
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
                fontWeight: FontWeight.w600, fontSize: 15),
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
          _FeedList(
            feedAsync: globalFeed,
            currentUid: currentUid,
            emptyMessage: 'No posts yet.\nBe the first to post!',
          ),
          _FeedList(
            feedAsync: followingFeed,
            currentUid: currentUid,
            emptyMessage:
                'Follow people to see\ntheir posts here.',
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
            color: Color(0xFF1D9BF0), strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: Text('Error loading feed',
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ),
      data: (posts) {
        final typedPosts = posts.cast<PostModel>();

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
              color: Colors.white.withOpacity(0.07), width: 1),
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
