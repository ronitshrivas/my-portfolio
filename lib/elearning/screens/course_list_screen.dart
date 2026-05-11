import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:innovator/elearning/model/course_list_model.dart';
import 'package:innovator/elearning/provider/course_provider.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';
import 'package:innovator/elearning/screens/course_details_screen.dart';
import 'package:innovator/elearning/screens/notifications_screen.dart';
import 'package:shimmer/shimmer.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _tabs = ['All', 'Free', 'Paid'];

  @override
  void initState() {
    super.initState();
    ref.refresh(courseListProvider);
    ref.refresh(enrollmentProvider);
    ref.refresh(elearningNotificationListProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(elearningNotificationListProvider.notifier).refresh();
    });
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CourseListModel> _filtered(List<CourseListModel> all, int tabIndex) {
    List<CourseListModel> list = all;

    if (tabIndex == 1) list = list.where((c) => c.isFree).toList();
    if (tabIndex == 2) list = list.where((c) => !c.isFree).toList();

    if (_selectedCategory != 'All') {
      list = list.where((c) => c.categoryName == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list =
          list
              .where((c) => c.title.toLowerCase().contains(_searchQuery))
              .toList();
    }

    return list;
  }

  // List<String> _categories(List<CourseListModel> all) {
  //   final cats = all.map((c) => c.categoryName).toSet().toList()..sort();
  //   return ['All', ...cats];
  // }

  List<String> _categories(List<CourseListModel> all) {
    final cats =
        all
            .map((c) => c.categoryName)
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final asyncCourses = ref.watch(courseListProvider);
    final unreadCount = ref.watch(chatUnreadCountProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: asyncCourses.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => _buildError(e),
          data: (courses) => _buildContent(courses),
        ),
      ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount, // ← real-time total
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) {
            ref.invalidate(mutualFriendsProvider);
            //ref.read(mutualFriendsProvider.notifier).refresh();
          });
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(null),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.78,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => _SkeletonCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Failed to load courses',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(courseListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<CourseListModel> courses) {
    final categories = _categories(courses);

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(courses),
          _buildCategoryChips(categories),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
              indicatorWeight: 2.5,
              isScrollable: false,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (tabIdx) {
                return AnimatedBuilder(
                  animation: _tabController,
                  builder: (_, __) {
                    final filtered = _filtered(courses, tabIdx);
                    if (filtered.isEmpty) return _buildEmpty();
                    return _buildGrid(filtered);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<CourseListModel>? courses) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'E-Learning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final unreadAsync = ref.watch(elearningUnreadCountProvider);
                    final count = unreadAsync;
                    return count > 0
                        ? Badge.count(
                          count: count,
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 25,
                          ),
                        )
                        : const Icon(Icons.notifications_outlined, size: 25);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = categories[i];
            final selected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color.fromRGBO(244, 135, 6, 1)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(List<CourseListModel> courses) {
    final enrolledIds = ref.watch(enrolledCoursesProvider);

    return CustomRefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(courseListProvider.future),
          ref.refresh(enrollmentProvider.future),
        ]);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 15,
          childAspectRatio: 0.78,
        ),
        itemCount: courses.length,
        itemBuilder: (_, i) {
          final course = courses[i];
          final isEnrolled = enrolledIds.contains(course.id);
          return _CourseCard(
            course: course,
            isEnrolled: isEnrolled,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: course),
                  ),
                ).then((_) {
                  ref
                      .read(elearningNotificationListProvider.notifier)
                      .refresh();
                  ref.refresh(enrollmentProvider);
                }),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No courses found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

//  Course Card

class _CourseCard extends StatelessWidget {
  final CourseListModel course;
  final bool isEnrolled;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.isEnrolled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child:
                        course.thumbnail != null
                            ? Image.network(
                              course.thumbnail!,
                              fit: BoxFit.fill,
                              errorBuilder:
                                  (_, __, ___) => _ThumbnailPlaceholder(),
                            )
                            : _ThumbnailPlaceholder(),
                  ),
                ),

                // Enrolled badge (top-left) — shown when enrolled
                if (isEnrolled)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(244, 135, 6, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 10,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Free badge (top-left) — only when NOT enrolled
                if (!isEnrolled && course.isFree)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Lock icon (top-right) — only paid & not enrolled
                if (!isEnrolled && !course.isFree)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (course.categoryName != null &&
                        course.categoryName!.isNotEmpty)
                      Text(
                        course.categoryName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child:
                              isEnrolled
                                  ? const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  )
                                  : course.isFree
                                  //  Free & not enrolled
                                  ? const Text(
                                    'Free',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  )
                                  //  Paid & not enrolled
                                  : Text(
                                    'Rs. ${course.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(244, 135, 6, 1),
                                    ),
                                  ),
                        ),
                        Icon(
                          isEnrolled
                              ? Icons.play_circle_filled
                              : Icons.play_circle_outline,
                          size: 18,
                          color:
                              isEnrolled
                                  ? const Color(0xFF2563EB)
                                  : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Thumbnail Placeholder

class _ThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          Icons.play_lesson_outlined,
          color: Colors.grey.shade400,
          size: 32,
        ),
      ),
    );
  }
}

//  Skeleton Card

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(height: 12, width: 80, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
