import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/auth_service.dart';

final authProvider = Provider<AuthService>((ref) {
 return AuthService();
});
