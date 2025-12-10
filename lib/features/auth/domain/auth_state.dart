import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:desperdicio_zero/models/user_profile.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(UserProfile user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.error(String message) = _Error;

  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}

