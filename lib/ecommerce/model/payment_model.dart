class PaymentModel {
  final String id;
  final String vendorId;
  final String vendorName;
  final String name;
  final String image;

  const PaymentModel({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    required this.image,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        vendorId: json['vendor_id'] as String,
        vendorName: json['vendor_name'] as String,
        name: json['name'] as String,
        image: json['image'] as String,
      );

  static List<PaymentModel> fromJsonList(List<dynamic> list) => list
      .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  String toString() => 'PaymentModel(name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PaymentModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}