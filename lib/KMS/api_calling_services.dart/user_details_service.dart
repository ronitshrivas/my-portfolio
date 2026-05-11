import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/model/user_details_model.dart';

class UserDetailsService extends BaseApiService {
  UserDetailsService() : super(dio: DioClient.instance);
  Future<UserDetailsModel> userData() async {
    final response = await get(ApiConstants.myProfile);
    return UserDetailsModel.fromJson(response); 
  }
}