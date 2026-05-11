import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/research/api_calling_service/research_service.dart';
import 'package:innovator/research/model/research_detail_model.dart';
import 'package:innovator/research/model/research_model.dart';  

final researchServiceProvider = Provider<ResearchService>(
  (_) => ResearchService(),
);
 

class ResearchFilter {
  final String? search;
  final String? type;   
  final String? status;  

  const ResearchFilter({this.search, this.type, this.status});

  ResearchFilter copyWith({
    Object? search = _sentinel,
    Object? type = _sentinel,
    Object? status = _sentinel,
  }) {
    return ResearchFilter(
      search: search == _sentinel ? this.search : search as String?,
      type: type == _sentinel ? this.type : type as String?,
      status: status == _sentinel ? this.status : status as String?,
    );
  }

  static const _sentinel = Object();
}

 
class ResearchListState {
  final List<ResearchPaperModel> papers;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final ResearchFilter filter;

  const ResearchListState({
    this.papers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.filter = const ResearchFilter(),
  });

  ResearchListState copyWith({
    List<ResearchPaperModel>? papers,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    bool? hasMore,
    ResearchFilter? filter,
  }) {
    return ResearchListState(
      papers: papers ?? this.papers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
    );
  }
}

 
class ResearchListNotifier extends StateNotifier<ResearchListState> {
  final ResearchService _service;
  static const _pageSize = 20;

  ResearchListNotifier(this._service) : super(const ResearchListState()) {
    fetchPapers();
  }

  Future<void> fetchPapers({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      papers: refresh ? [] : state.papers,
      currentPage: refresh ? 1 : state.currentPage,
      hasMore: refresh ? true : state.hasMore,
    );

    try {
      final response = await _service.getResearchPapers(
        search: state.filter.search,
        type: state.filter.type,
        status: state.filter.status,
        page: 1,
        limit: _pageSize,
      );
      state = state.copyWith(
        papers: response.data,
        isLoading: false,
        currentPage: 1,
        hasMore: response.data.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _service.getResearchPapers(
        search: state.filter.search,
        type: state.filter.type,
        status: state.filter.status,
        page: nextPage,
        limit: _pageSize,
      );
      state = state.copyWith(
        papers: [...state.papers, ...response.data],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: response.data.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> applyFilter(ResearchFilter filter) async {
    state = state.copyWith(filter: filter);
    await fetchPapers(refresh: true);
  }

  Future<void> refresh() => fetchPapers(refresh: true);
}

final researchListProvider =
    StateNotifierProvider<ResearchListNotifier, ResearchListState>(
  (ref) => ResearchListNotifier(ref.watch(researchServiceProvider)),
);

 
class UploadState {
  final bool isUploading;
  final double progress; 
  final bool isSuccess;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.progress = 0,
    this.isSuccess = false,
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

 
class UploadNotifier extends StateNotifier<UploadState> {
  final ResearchService _service;
  final Ref _ref;

  UploadNotifier(this._service, this._ref) : super(const UploadState());

  Future<bool> upload({
    required String email,
    required String title,
    String? description,
    required String type,
    double? price,
    List<String>? researcherNames,
    required PlatformFile paperFile,
    PlatformFile? researcherFile,
  }) async {
    state = const UploadState(isUploading: true);

    try {
      await _service.uploadResearchPaper(
        email: email,
        title: title,
        description: description,
        type: type,
        price: price,
        researcherNames: researcherNames,
        paperFile: paperFile,
        researcherFile: researcherFile,
        onSendProgress: (sent, total) {
          if (total > 0) state = state.copyWith(progress: sent / total);
        },
      );

      state = const UploadState(isSuccess: true); 
      _ref.read(researchListProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = UploadState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const UploadState();
}

final uploadResearchPaperProvider =
    StateNotifierProvider<UploadNotifier, UploadState>(
  (ref) => UploadNotifier(ref.watch(researchServiceProvider), ref),
);

class ResearchDetailState {
  final ResearchPaperDetailResponseModel? data;
  final bool isLoading;
  final String? error;
 
  const ResearchDetailState({
    this.data,
    this.isLoading = false,
    this.error,
  });
 
  ResearchDetailState copyWith({
    ResearchPaperDetailResponseModel? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ResearchDetailState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
 

class ResearchDetailNotifier extends StateNotifier<ResearchDetailState> {
  ResearchDetailNotifier(this._ref, this._paperId)
      : super(const ResearchDetailState()) {
    fetch();
  }
 
  final Ref _ref;
  final int _paperId;
 
  Future<void> fetch() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _ref
          .read(researchServiceProvider)
          .getResearchPaperById(_paperId);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
 
  Future<void> refresh() => fetch();
}
final researchDetailProvider = StateNotifierProvider.family<
    ResearchDetailNotifier, ResearchDetailState, int>(
  (ref, paperId) => ResearchDetailNotifier(ref, paperId),
);