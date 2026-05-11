class ResearchApi {
  // static const String baseUrl = 'http://36.253.137.34:8004/api';
  static const String baseUrl = 'https://api.meta-tronix.com';
  static const String getResearchPaper = '$baseUrl/research';
  static String getResearchPaperById(int researchId) =>
      '$baseUrl/research/$researchId';
  static const String researchPageUpload = '$baseUrl/research/upload';
  static String paymentInitiate(int paperId) =>
      '$baseUrl/payment/initiate/$paperId';
  static String getLimitedPaper(int page, int limit) =>
      '$baseUrl/research?$page&$limit';

  // time out
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
