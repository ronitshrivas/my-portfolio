import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/core/cache/hive_cache.dart';
import 'package:innovator/elearning/data/models/elearning_dtos.dart';
import 'package:innovator/elearning/data/sources/elearning_api.dart';

final elearningApiProvider = Provider<ElearningApi>((_) => ElearningApi());

final elearningCacheProvider =
    FutureProvider<HiveCache>((_) => HiveCache.open('elearning'));

/// Course catalog — instant from Hive, then refreshed.
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final api = ref.watch(elearningApiProvider);
  final cache = ref.watch(elearningCacheProvider).valueOrNull;

  final courses = await api.courses();
  cache?.put('courses', courses.map((e) => e.toJson()).toList());
  return courses;
});

/// The current student's enrollments.
final enrollmentsProvider = FutureProvider<List<Enrollment>>((ref) {
  return ref.watch(elearningApiProvider).enrollments();
});

final elearningNotificationsProvider =
    FutureProvider<List<ElearningNotification>>((ref) {
  return ref.watch(elearningApiProvider).notifications();
});
