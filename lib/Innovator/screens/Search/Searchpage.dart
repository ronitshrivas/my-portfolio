import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/Search/search_provider.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/Innovator/screens/suggested_users/suggested_user_screen.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.whitecolor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleHeader(),
              _buildSimpleSearchBar(notifier),
              const SizedBox(height: 8),

              if (searchState.isSearching)
                Expanded(child: _buildSearchResults(searchState)),

              if (!searchState.isSearching)
                Expanded(child: const SuggestedUsersSection()),
            ],
          ),
        ),
      ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount,
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) => ref.invalidate(mutualFriendsProvider));
        },
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.whitecolor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search,
              color: AppColors.whitecolor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find People',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Discover and connect with others',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSearchBar(SearchNotifier notifier) {
    return SearchBar(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(Colors.grey[100]!),
      hintText: 'Search for people...',
      controller: _searchController,
      leading: const Icon(Icons.search, color: Colors.grey),
      trailing: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            splashRadius: 16,
            onPressed: () {
              _searchController.clear();
              notifier.search('');
              setState(() {});
            },
          ),
      ],
      onChanged: (value) {
        notifier.search(value);
        setState(() {});
      },
      onTap: () {
        _searchController.clear();
        notifier.fetchSuggested();
        setState(() {});
      },
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 14),
            Text('Searching...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (searchState.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 14),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      itemCount: searchState.users.length,
      itemBuilder: (context, index) => _buildUserCard(searchState.users[index]),
    );
  }

  Widget _buildUserCard(SearchUser user) {
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpecificUserProfilePage(userId: user.id),
            ),
          ),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Row(
            children: [
              _buildSearchAvatar(user),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Divider(thickness: 2, color: Colors.grey[300], height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchAvatar(SearchUser user) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[300],
      backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
      child:
          user.avatar == null
              ? Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whitecolor,
                ),
              )
              : null,
    );
  }
}
