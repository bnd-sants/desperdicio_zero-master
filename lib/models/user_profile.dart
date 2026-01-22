import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // CORREÇÃO: Implementação manual para lidar com snake_case e nulls
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      // Garante que não quebre se vier null
      id: json['id'] as String? ?? '', 
      email: json['email'] as String? ?? '',
      
      // Tenta ler 'fullName' (Dart) OU 'full_name' (Supabase). Se ambos null, usa 'Usuário'
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? 'Usuário',
      
      // Tenta ler 'avatarUrl' (Dart) OU 'avatar_url' (Supabase)
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      
      // Converte datas de string para DateTime com segurança (created_at do Supabase)
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
          
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  // Mantemos o padrão para envio, ou ajustamos se precisar enviar snake_case para o banco
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName, // Enviando como snake_case para o Supabase entender
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}