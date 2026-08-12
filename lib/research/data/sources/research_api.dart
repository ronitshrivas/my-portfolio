import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/research/data/models/research_dtos.dart';

/// Research service — http://36.253.137.34:8019/swagger
/// Serves paths WITHOUT an /api prefix.
class ResearchApi {
  ResearchApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;
  static const _base = ApiConfig.researchBaseUrl;

  Future<ResearchPage> papers({
    String? search,
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final envelope = await _client.get<ResearchPage>(
      _base,
      '/research',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      parse: (raw) => ResearchPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const ResearchPage();
  }

  Future<ResearchDetail?> paper(int id) async {
    final envelope = await _client.get<ResearchDetail?>(
      _base,
      '/research/$id',
      parse: (raw) => raw is Map
          ? ResearchDetail.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
    return envelope.data;
  }

  Future<void> upload({
    required String email,
    required String title,
    required String type,
    required Uint8List paperFile,
    String paperFilename = 'paper.pdf',
    String? description,
    int? price,
    List<String> researcherNames = const [],
    Uint8List? researcherFile,
    String researcherFilename = 'researcher.pdf',
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();
    formData.fields
      ..add(MapEntry('email', email))
      ..add(MapEntry('title', title))
      ..add(MapEntry('type', type));
    if (description != null && description.isNotEmpty) {
      formData.fields.add(MapEntry('description', description));
    }
    if (price != null && type == 'paid') {
      formData.fields.add(MapEntry('price', '$price'));
    }
    if (researcherNames.isNotEmpty) {
      formData.fields.add(MapEntry('researcher_names', researcherNames.join(',')));
    }
    formData.files.add(MapEntry(
      'paper_file',
      MultipartFile.fromBytes(paperFile, filename: paperFilename),
    ));
    if (researcherFile != null) {
      formData.files.add(MapEntry(
        'researcher_files',
        MultipartFile.fromBytes(researcherFile, filename: researcherFilename),
      ));
    }

    await _client.upload<Object?>(
      _base,
      '/research/upload',
      formData: formData,
      onSendProgress: onSendProgress,
      parse: (_) => null,
    );
  }

  Future<String?> initiatePayment(int paperId) async {
    final envelope = await _client.post<String?>(
      _base,
      '/payment/initiate/$paperId',
      parse: (raw) => raw is Map
          ? (raw['payment_url'] ?? raw['url'])?.toString()
          : raw?.toString(),
    );
    return envelope.data;
  }
}
