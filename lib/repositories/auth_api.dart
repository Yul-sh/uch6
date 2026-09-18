import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import 'api_tour_repository.dart';

/// Auth against PocketBase `users` collection.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Options get _noRefresh => Options(extra: {'skipAuthRefresh': true});

  /// Accepts email or short demo login: client / manager / admin.
  static String normalizeIdentity(String raw) {
    final value = raw.trim();
    if (value.contains('@')) return value;
    return switch (value.toLowerCase()) {
      'client' => 'client@flyy.local',
      'manager' => 'manager@flyy.local',
      'admin' => 'admin@flyy.local',
      _ => value.contains('@') ? value : '$value@flyy.local',
    };
  }

  Future<AuthTokens> login(String username, String password) => guard(() async {
    final response = await _dio.post<dynamic>(
      '/collections/users/auth-with-password',
      data: {'identity': normalizeIdentity(username), 'password': password},
      options: _noRefresh,
    );
    return AuthTokens.fromJson(asJsonMap(response.data));
  });

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) => guard(() async {
    final email = normalizeIdentity(username);
    await _dio.post<dynamic>(
      '/collections/users/records',
      data: {
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'displayName': displayName,
        'role': 'client',
        'emailVisibility': true,
      },
      options: _noRefresh,
    );
    return login(email, password);
  });

  Future<AppUser> me() => guard(() async {
    final response = await _dio.post<dynamic>(
      '/collections/users/auth-refresh',
      options: _noRefresh,
    );
    final data = asJsonMap(response.data);
    final record = data['record'] is Map
        ? Map<String, dynamic>.from(data['record'] as Map)
        : data;
    return AppUser.fromJson(record);
  });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post<dynamic>(
      '/collections/users/auth-refresh',
      options: Options(
        extra: {'skipAuthRefresh': true},
        headers: {'Authorization': refreshToken},
      ),
    );
    return AuthTokens.fromJson(asJsonMap(response.data));
  });
}
