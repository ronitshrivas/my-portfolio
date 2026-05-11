import 'package:flutter_riverpod/flutter_riverpod.dart';

final postUploadingProvider = StateProvider<bool>((ref) => false);
final postUploadMessageProvider = StateProvider<String?>((ref) => null);