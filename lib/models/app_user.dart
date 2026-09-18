import '../data/json_codec.dart';
import 'role.dart';

class AppUser {
  final String id;
  final String username;
  final String displayName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final email = jsonString(json['email']);
    final username = jsonString(
      json['username'],
      email.isNotEmpty ? email : jsonId(json['id']),
    );
    return AppUser(
      id: jsonId(json['id']),
      username: username,
      displayName: jsonString(
        json['displayName'],
        username.isNotEmpty ? username : 'User',
      ),
      role: roleFromApi(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'role': role.apiName,
  };

  AppUser copyWith({Role? role, String? displayName}) => AppUser(
    id: id,
    username: username,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
  );
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final record = json['record'] is Map
        ? Map<String, dynamic>.from(json['record'] as Map)
        : (json['user'] is Map
              ? Map<String, dynamic>.from(json['user'] as Map)
              : json);
    final token = jsonString(json['token'] ?? json['accessToken']);
    return AuthTokens(
      accessToken: token,
      refreshToken: jsonString(json['refreshToken'], token),
      user: AppUser.fromJson(record),
    );
  }
}
