class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  static const String _host = 'http://36.253.137.34';

  // Direct service ports (gateway on 8005 is bypassed):
  //   8010 auth · 8011 profile/users · 8012 feed · 8014 chat · 8015 search
  static const String _feedHost = '$_host:8012';
  static const String _profileHost = '$_host:8011';
  static const String _chatHost = '$_host:8014';
  static const String _searchHost = '$_host:8015';

  //Base Urls
  static const String studentBase = '$_host:8003/api/student';
  static const String authBase = '$_host:8010/api/auth';
  static const String mediaBase = '$_host:8003';
  static const String feedBase = '$_feedHost/api';
  static const String profileApi = '$_profileHost/api';
  static const String chatApi = '$_chatHost/api';
  static const String searchApi = '$_searchHost/api';
  static const String userBase = _feedHost;

  //Auth Username Checkusername  (auth service, /api/users/check-username?username=)
  static const String checkusername = '$_host:8010/api/users/check-username';

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

  static const String reportuser = '$profileApi/users/';

  static const String blockuser = '$profileApi/users/';

  static const String blocklistuser = '$profileApi/users/blocked-list';

  static const String unblockuser = '$profileApi/users/';

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

  static const String fetchuuid = '$profileApi/users/';

  static const String sendFollowrequest = '$profileApi/users/';

  static const String sendreaction = '$feedBase/reactions/';

  static const String fetchreactions = '$feedBase/posts/';

  static const String profile = '$profileApi/profile';

  static const String avatarurl = '$profileApi/users/me/avatar/';

  static const String fetchuserprofile = '$profileApi/users/me';

  static const String updateuserprofilepicture = '$profileApi/users/me/avatar/';

  static const String getfollowers = '$profileApi/users/followers/';

  static const String getfollowing = '$profileApi/users/following/';

  static const String fetchreports = '$profileApi/users/reports-list/';

  static const String fetchsuggestionusers = '$searchApi/suggested-users/';

  static const String fetchspecificfollowersandfollowing = '$profileApi/users/';

  static const String fetchotheruserprofile = '$profileApi/users/';

  static const String fetchreporstCount = '$feedBase/posts/';

  // For chatting
  static const String mutualfriends = '$profileApi/users/mutual-friends/';

  static const String chatshistry = '$chatApi/chats/';

  static const String deleteconversation =
      '$chatApi/chats/delete-conversation/';

  static const String markasread = '$chatApi/chats/mark-as-read/';

  static const String connect = '$_chatHost/ws/chat/';
  static const String chatPreferences = '$chatApi/chat-preferences/';
}
