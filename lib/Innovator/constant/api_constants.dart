class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  static const String _host = 'http://36.253.137.34';

  //Base Urls
  static const String studentBase = '$_host:8003/api/student';
  static const String authBase = '$_host:8010/api/auth';
  static const String mediaBase = '$_host:8003';
  static const String feedBase = '$_host:8005/api';
  static const String userBase = '$_host:8005';

  //Auth Username Checkusername
  static const String checkusername = '$feedBase/users/check-username/';

  //
  static const String fetchreelreactions = '$feedBase/reels/';

  //Auth Endpoints
  static const String tokenRefresh = '$authBase/token/refresh/';

  // Student endpoints
  static const String courses = '$studentBase/courses/';
  static const String enrollments = '$studentBase/enrollments/';

  //change password
  static const String changePassword = '$authBase/change-password/';

  //Login Endpointts
  static const String login = '$authBase/sso/login/';

  //verify email

  // Resend Verification OTP Endpoints
  static const String resendVerificationOTP =
      '$authBase/resend-verification-otp';

  //Forgot password Endpoints
  static const String forgotPassword = '$authBase/forgot-password/';
  static const String verifyOtp = '$authBase/forgot-password/verify/';
  static const String resetPassword =
      '$authBase/forgot-password/reset-password/';
  static const String resendOtp = '$authBase/resend-otp/';

  //Send OTP Endpoints
  static const String sendOTP = '$authBase/send-otp';

  //Register Endponits
  static const String register = '$authBase/register/';

  //Social Media Endpoints
  static const String post = '$feedBase/feed/';

  static const String recordview = '$feedBase/posts/';

  static const String reportuser = '$feedBase/users/';

  static const String blockuser = '$feedBase/users/';

  static const String blocklistuser = '$feedBase/users/blocked-list/';

  static const String unblockuser = '$feedBase/users/';

  static const String getcomments = '$feedBase/comments/';

  static const String getcommentreplies = '$feedBase/replies/';

  static const String addcomments = '$feedBase/comments/';

  static const String addcommentreplies = '$feedBase/replies/';

  static const String updatecomments = '$feedBase/comments/';

  static const String updatecommentreplies = '$feedBase/replies/';

  static const String deletecomment = '$feedBase/comments/';

  static const String deletecommentreplies = '$feedBase/replies/';

  // Create Post Fetch Categories

  static const String fetchcategories = '$feedBase/categories/';

  static const String createpost = '$feedBase/posts/';

  static const String fetchuuid = '$feedBase/users/';

  static const String sendFollowrequest = '$feedBase/users/';

  static const String sendreaction = '$feedBase/reactions/';

  static const String fetchreactions = '$feedBase/posts/';

  static const String profile = '$feedBase/profile/';

  static const String avatarurl = '$feedBase/users/me/avatar/';

  static const String fetchuserprofile = '$feedBase/users/me';

  static const String updateuserprofilepicture = '$feedBase/users/me/avatar/';

  static const String getfollowers = '$feedBase/users/followers/';

  static const String getfollowing = '$feedBase/users/following/';

  static const String fetchreports = '$feedBase/users/reports-list/';

  static const String fetchsuggestionusers = '$feedBase/suggested-users/';

  static const String fetchspecificfollowersandfollowing = '$feedBase/users/';

  static const String fetchotheruserprofile = '$feedBase/users/';

  static const String fetchreporstCount = '$feedBase/posts/';

  // For chatting
  static const String mutualfriends = '$feedBase/users/mutual-friends/';

  static const String chatshistry = '$feedBase/chats/';

  static const String deleteconversation =
      '$feedBase/chats/delete-conversation/';

  static const String markasread = '$feedBase/chats/mark-as-read/';

  static const String connect = '$userBase/ws/chat/';
  static const String chatPreferences = '$feedBase/chat-preferences/';
}
