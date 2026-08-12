import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/core/cache/hive_cache.dart';
import 'package:innovator/events/data/models/event_dtos.dart';
import 'package:innovator/events/data/sources/events_api.dart';

final eventsApiProvider = Provider<EventsApi>((_) => EventsApi());

final eventsCacheProvider =
    FutureProvider<HiveCache>((_) => HiveCache.open('events'));

/// Event list — instant from Hive, then refreshed.
final eventsProvider = FutureProvider<List<EventDto>>((ref) async {
  final api = ref.watch(eventsApiProvider);
  final cache = ref.watch(eventsCacheProvider).valueOrNull;

  final events = await api.events();
  cache?.put('events', events.map((e) => e.toJson()).toList());
  return events;
});
