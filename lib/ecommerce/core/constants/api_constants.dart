class EcommerceApi {
  // static const String baseUrl = 'http://36.253.137.34:8004/api';
  static const String baseUrl = 'http://36.253.137.34:8004/api';
  static const String productList = '$baseUrl/products';
  static const String cartItems = '$baseUrl/cart-items/';
  static const String productDetails = '$baseUrl/products/';
  static String itemUpdate(String id) => '$baseUrl/cart-items/$id/';
  static const String checkout = '$baseUrl/checkout/summary/';
  static String checkoutSummary = '$baseUrl/checkout/summary/';
  static String payment = '$baseUrl/payment-qrs/public-list/';
  static String orders(String orderId) =>
      '$baseUrl/orders/$orderId/confirm-payment/';
  static String khaltiPayment = '$baseUrl/payments/initiate/';

  //  notifications
  static const String fcmTokens = '$baseUrl/fcm-tokens/';
  static const String notificationsList = '$baseUrl/notifications/';
  static String markNotificationAsRead(String notificationId) =>
      '$baseUrl/notifications/$notificationId/mark-read/';
  static const String markAllNotificationsAsRead =
      '$baseUrl/notifications/mark-all-read/';

  // time out
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
