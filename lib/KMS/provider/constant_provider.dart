import 'package:flutter_riverpod/flutter_riverpod.dart';

final obscureProvider = StateProvider.family<bool, String>((ref, id) => true);
