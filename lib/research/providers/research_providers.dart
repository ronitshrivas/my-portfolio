import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/core/cache/hive_cache.dart';
import 'package:innovator/research/data/models/research_dtos.dart';
import 'package:innovator/research/data/sources/research_api.dart';

final researchApiProvider = Provider<ResearchApi>((_) => ResearchApi());

final researchCacheProvider =
    FutureProvider<HiveCache>((_) => HiveCache.open('research'));

/// Research papers — instant from Hive, then refreshed.
final researchPapersProvider = FutureProvider<List<ResearchPaper>>((ref) async {
  final api = ref.watch(researchApiProvider);
  final cache = ref.watch(researchCacheProvider).valueOrNull;

  final page = await api.papers();
  cache?.put('papers', page.data.map((e) => e.toJson()).toList());
  return page.data;
});

final researchDetailProvider =
    FutureProvider.family<ResearchDetail?, int>((ref, id) {
  return ref.watch(researchApiProvider).paper(id);
});
