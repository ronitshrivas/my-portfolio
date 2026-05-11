import 'package:innovator/Innovator/models/Chat/mutual_friend_model.dart';

class MutualFriendsState {
  final List<MutualFriend> friends;
  final int totalCount;
  final bool isLoading;
  final String? error;

  const MutualFriendsState({
    this.friends = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
  });

  MutualFriendsState copyWith({
    List<MutualFriend>? friends,
    int? totalCount,
    bool? isLoading,
    String? error,
  }) => MutualFriendsState(
    friends: friends ?? this.friends,
    totalCount: totalCount ?? this.totalCount,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  List<MutualFriend> get onlineFriends =>
      friends.where((f) => f.onlineStatus).toList();

  List<MutualFriend> get offlineFriends =>
      friends.where((f) => !f.onlineStatus).toList();

  int get totalUnread => friends.fold(0, (sum, f) => sum + f.unreadCount);
}
