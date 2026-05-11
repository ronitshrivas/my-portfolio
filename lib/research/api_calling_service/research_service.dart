import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:innovator/research/core/constants/api_constants.dart';
import 'package:innovator/research/core/constants/network/base_api_service.dart';
import 'package:innovator/research/core/constants/network/dio_client.dart';
import 'package:innovator/research/model/research_detail_model.dart';
import 'package:innovator/research/model/research_model.dart'; 

class ResearchService extends ResearchBaseApiService {
  ResearchService() : super(dio: DioClient.instance);

  Future<ResearchPaperResponseModel> getResearchPapers({
    String? search,
    String? type,    
    String? status,  
    int page = 1,
    int limit = 20,
  }) async {
    final data = await get<Map<String, dynamic>>(
      ResearchApi.getResearchPaper,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null && type.isNotEmpty) 'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return ResearchPaperResponseModel.fromJson(data);
  }

  Future<void> uploadResearchPaper({
    required String email,
    required String title,
    String? description,
    required String type,      
    double? price,
    List<String>? researcherNames,
    required PlatformFile paperFile,
    PlatformFile? researcherFile,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'email': email,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'type': type,
      if (price != null && type == 'paid') 'price': price.toInt(),
      if (researcherNames != null && researcherNames.isNotEmpty)
        'researcher_names': researcherNames.join(','),
      'paper_file': await MultipartFile.fromFile(
        paperFile.path!,
        filename: paperFile.name,
      ),
      if (researcherFile != null)
        'researcher_files': await MultipartFile.fromFile(
          researcherFile.path!,
          filename: researcherFile.name,
        ),
    });

    await upload(
      ResearchApi.researchPageUpload,
      formData,
      onSendProgress: onSendProgress,
    );
  }


    Future<ResearchPaperDetailResponseModel> getResearchPaperById(
      int id) async {
    final data = await get<Map<String, dynamic>>( 
      ResearchApi.getResearchPaperById(id)
    );
    return ResearchPaperDetailResponseModel.fromJson(data);
  }
}