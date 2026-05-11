import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

const String _baseUrl = 'http://36.253.137.34:8005';

class SearchUser {
  final String id;
  final String username;
  final String? avatar;

  const SearchUser({required this.id, required this.username, this.avatar});

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    String? avatar =
        json['profile']?['avatar'] as String? ?? json['avatar'] as String?;
    if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
      avatar = '$_baseUrl$avatar';
    }
    return SearchUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      avatar: (avatar?.isEmpty ?? true) ? null : avatar,
    );
  }
}

class SearchState {
  final List<SearchUser> users;
  final bool isLoading;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.users = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    List<SearchUser>? users,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) => SearchState(
    users: users ?? this.users,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    error: error,
  );
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState()) {
    fetchSuggested();
  }

  final _appData = AppData();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_appData.accessToken != null)
      'authorization': 'Bearer ${_appData.accessToken}',
  };

  Future<void> fetchSuggested() async {
    state = state.copyWith(isLoading: true, isSearching: false, error: null);
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.fetchsuggestionusers),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final raw = json.decode(response.body) as List<dynamic>;
        state = state.copyWith(
          users: _deduped(raw).take(10).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load suggestions',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      fetchSuggested();
      return;
    }
    state = state.copyWith(isLoading: true, isSearching: true, error: null);
    try {
      // Use real search endpoint with ?search= param
      final uri = Uri.parse(
        '$_baseUrl/api/users/',
      ).replace(queryParameters: {'search': query.trim()});
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final raw = json.decode(response.body) as List<dynamic>;
        state = state.copyWith(users: _deduped(raw), isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Search failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<SearchUser> _deduped(List<dynamic> raw) {
    final seen = <String>{};
    return raw
        .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
        .where((u) => u.id.isNotEmpty && seen.add(u.id))
        .toList();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (_) => SearchNotifier(),
);
