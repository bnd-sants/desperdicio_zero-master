import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/features/auth/domain/auth_state.dart';
import 'auth_notifier.dart';

final authNotifierProvider = NotifierProvider.autoDispose<AuthNotifier, AuthState>(AuthNotifier.new);
