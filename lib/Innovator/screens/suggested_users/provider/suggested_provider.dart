import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/screens/suggested_users/model/suggested_users_model.dart';
import 'package:innovator/Innovator/screens/suggested_users/service/suggested_user_service.dart';

final suggestServiceProvider = Provider<SuggestedUserService>(
  (ref) => SuggestedUserService(),
);



final suggestProvider = FutureProvider<SuggestionResponse>((ref) {
  final suggestion = ref.read(suggestServiceProvider);
  return suggestion.suggestedUser();
},);