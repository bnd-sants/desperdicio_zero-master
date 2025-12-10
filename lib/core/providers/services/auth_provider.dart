import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
