// import 'package:innovator/KMS/core/constants/api_constants.dart';
// import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
// import 'package:innovator/KMS/core/constants/network/dio_client.dart';
// import 'package:innovator/KMS/model/admin_model/school_list_model.dart';

// class AdminService extends BaseApiService {
//   AdminService() : super(dio: DioClient.instance);

//   Future<List<SchoolListModel>> getSchoolList() async {
//     final data = await get<List<dynamic>>(ApiConstants.schoolList);
//     return data
//         .map((item) => SchoolListModel.fromJson(item as Map<String, dynamic>))
//         .toList();
//   }

//   Future<void> createSchool({
//     required String name,
//     required String address,
//   }) async {
//     return await post(
//       ApiConstants.createSchool,
//       data: {'name': name, 'address': address},
//     );
//   }

//   Future<void> deleteSchoolById({required String schoolId}) async {
//     await delete(ApiConstants.specificSchoolId(schoolId));
//   }

//  Future<SchoolListModel> getSchoolById({required String schoolId}) async {
//   final data = await get<Map<String, dynamic>>(
//     ApiConstants.specificSchoolId(schoolId),
//   );
//   return SchoolListModel.fromJson(data);
// }
// }
