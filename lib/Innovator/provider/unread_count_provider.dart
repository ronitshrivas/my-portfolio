import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-friend unread counts — keyed by friend's user ID.
/// ChatNotifier increments this when a new WS message arrives.
/// MutualFriendsNotifier reads/resets this when loading the list.
final perFriendUnreadProvider =
    StateNotifierProvider<PerFriendUnreadNotifier, Map<String, int>>(
      (ref) => PerFriendUnreadNotifier(),
    );

final lastActiveFriendProvider = StateProvider<String?>((ref) => null);

final friendActivityProvider =
    StateNotifierProvider<FriendActivityNotifier, Map<String, DateTime>>(
      (ref) => FriendActivityNotifier(),
    );

class PerFriendUnreadNotifier extends StateNotifier<Map<String, int>> {
  PerFriendUnreadNotifier() : super({});

  /// Increment unread count for a friend (called by ChatNotifier on new WS msg)
  void increment(String friendId) {
    final current = state[friendId] ?? 0;
    state = {...state, friendId: current + 1};
  }

  /// Reset count for a friend (called when user opens that chat / marks read)
  void reset(String friendId) {
    if ((state[friendId] ?? 0) == 0) return;
    state = {...state, friendId: 0};
  }

  /// Seed counts from REST history fetch (called by MutualFriendsNotifier)
  void seedFromHistory(Map<String, int> counts) {
    state = {...state, ...counts};
  }

  /// Total unread across all friends
  int get total => state.values.fold(0, (a, b) => a + b);

  int countFor(String friendId) => state[friendId] ?? 0;
}

class FriendActivityNotifier extends StateNotifier<Map<String, DateTime>> {
  FriendActivityNotifier() : super({});

  void markActivity(String friendId) {
    state = {...state, friendId: DateTime.now()};
  }

  //DateTime? lastActivityFor(String friendId) => state[friendId];
}
