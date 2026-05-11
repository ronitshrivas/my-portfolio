
class EcommerceNotificationData {
  final String type;
  final String productId;
  final String categroy;

  const EcommerceNotificationData({
    required this.type,
    required this.productId,
    required this.categroy,
  });

  factory EcommerceNotificationData.fromJson(Map<String, dynamic> json) {
    return EcommerceNotificationData(
      type: json['type'] ??'',
      productId: json['product_id'] ??'',
      categroy: json['category'] ??'',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'product_id': productId,
    'category': categroy,
  };
}

class EcommerceNotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final EcommerceNotificationData data;

  const EcommerceNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory EcommerceNotificationModel.fromJson(Map<String, dynamic> json) {
    return EcommerceNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: EcommerceNotificationData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'notification_type': notificationType,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'data': data.toJson(),
  };

   static List<EcommerceNotificationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
      .map((e) => EcommerceNotificationModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }
}


