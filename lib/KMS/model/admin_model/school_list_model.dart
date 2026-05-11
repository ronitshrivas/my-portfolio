// class SchoolListModel {
//   final String? id;
//   final String? name;
//   final String? address;
//   final DateTime? createdAt;

//   SchoolListModel({
//     this.id,
//     this.name,
//     this.address,
//     this.createdAt,
//   });
//   factory SchoolListModel.fromJson(Map<String, dynamic> json) {
//     return SchoolListModel(
//       id: json['id'] as String?,
//       name: json['name'] as String?,
//       address: json['address'] as String?,
//       createdAt: json['created_at'] != null
//           ? DateTime.tryParse(json['created_at'] as String)
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'address': address,
//       'created_at': createdAt?.toIso8601String(),
//     };
//   }
// }