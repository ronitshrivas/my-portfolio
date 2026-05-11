// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/constant/app_colors.dart';
// import 'package:innovator/Innovator/models/Author_model.dart';
// import 'package:innovator/Innovator/controllers/user_controller.dart';

// class InstantProfilePicture extends StatelessWidget {
//   final String userId;
//   final double radius;
//   final String? fallbackName;
//   final String? fallbackImageUrl;
//   final Author? authorData;
//   final bool cacheIfMissing;

//   const InstantProfilePicture({
//     Key? key,
//     required this.userId,
//     this.radius = 25,
//     this.fallbackName,
//     this.fallbackImageUrl,
//     this.authorData,
//     this.cacheIfMissing = true,
//     required Map<String, dynamic> profileData,
//     required bool showBorder, // NEW
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<UserController>(
//       builder: (userController) {
//         // Check if it's current user
//         if (userId == AppData().currentUserId) {
//           return Obx(() => _buildCurrentUserAvatar(userController));
//         }

//         // For other users - try to get cached data first
//         String? imageUrl = userController.getOtherUserFullProfilePicturePath(
//           userId,
//         );
//         String? displayName = userController.getOtherUserName(userId);

//         //  If no cached data but we have author data, cache it and use it
//         if ((imageUrl == null || displayName == null) &&
//             authorData != null &&
//             cacheIfMissing) {
//           userController.cacheUserProfilePicture(
//             authorData!.id,
//             authorData!.picture.isNotEmpty ? authorData!.picture : null,
//             authorData!.name.isNotEmpty ? authorData!.name : null,
//           );

//           // Update variables after caching
//           imageUrl = userController.getOtherUserFullProfilePicturePath(userId);
//           displayName = userController.getOtherUserName(userId);
//         }

//         //Fallback chain with better priority
//         final finalImageUrl =
//             imageUrl ??
//             (authorData?.picture.isNotEmpty == true
//                 ? _formatAuthorPictureUrl(authorData!.picture)
//                 : fallbackImageUrl);

//         final finalDisplayName =
//             displayName ?? authorData?.name ?? fallbackName ?? '?';

//         return _buildOtherUserAvatar(finalImageUrl, finalDisplayName);
//       },
//     );
//   }

//   Widget _buildCurrentUserAvatar(UserController userController) {
//     return CircleAvatar(
//       radius: radius,
//       backgroundColor: Colors.grey[300],
//       backgroundImage:
//           userController.profilePicture.value != null &&
//                   userController.profilePicture.value!.isNotEmpty
//               ? CachedNetworkImageProvider(
//                 '${userController.getFullProfilePicturePath()}?v=${userController.profilePictureVersion.value}',
//                 cacheKey:
//                     'current_user_${userController.profilePictureVersion.value}',
//               )
//               : null,
//       child:
//           userController.profilePicture.value == null ||
//                   userController.profilePicture.value!.isEmpty
//               ? Text(
//                 (userController.userName.value ?? fallbackName ?? '?')[0]
//                     .toUpperCase(),
//                 style: TextStyle(
//                   fontSize: radius * 0.7,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.whitecolor,
//                 ),
//               )
//               : null,
//     );
//   }

//   Widget _buildOtherUserAvatar(String? imageUrl, String displayName) {
//     return CircleAvatar(
//       radius: radius,
//       backgroundColor: Colors.grey[300],
//       child:
//           imageUrl != null && imageUrl.isNotEmpty
//               ? ClipOval(
//                 child: CachedNetworkImage(
//                   imageUrl: imageUrl,
//                   width: radius * 2,
//                   height: radius * 2,
//                   fit: BoxFit.cover,

//                   cacheKey: 'user_${userId}_${imageUrl.hashCode}',

//                   errorWidget:
//                       (context, url, error) => Container(
//                         width: radius * 2,
//                         height: radius * 2,
//                         color: Colors.grey[400],
//                         child: Center(
//                           child: Text(
//                             displayName.toUpperCase(),
//                             style: TextStyle(
//                               fontSize: radius * 0.7,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.whitecolor,
//                             ),
//                           ),
//                         ),
//                       ),
//                 ),
//               )
//               : Text(
//                 displayName[0].toUpperCase(),
//                 style: TextStyle(
//                   fontSize: radius * 0.7,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.whitecolor,
//                 ),
//               ),
//     );
//   }

//   String _formatAuthorPictureUrl(String picture) {
//     if (picture.startsWith('http')) {
//       return picture;
//     }
//     return 'http://182.93.94.210:3067${picture.startsWith('/') ? picture : '/$picture'}';
//   }
// }
