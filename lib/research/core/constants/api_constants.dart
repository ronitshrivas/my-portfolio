class ResearchApi {
  // ResearchService (8019) serves paths without an /api prefix.
  static const String baseUrl = 'http://36.253.137.34:8019';
  static const String getResearchPaper = '$baseUrl/research';
  static String getResearchPaperById(int researchId) =>
      '$baseUrl/research/$researchId';
  static const String researchPageUpload = '$baseUrl/research/upload';
  static String paymentInitiate(int paperId) =>
      '$baseUrl/payment/initiate/$paperId';
  static String getLimitedPaper(int page, int limit) =>
      '$baseUrl/research?page=$page&limit=$limit';

  // time out
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
