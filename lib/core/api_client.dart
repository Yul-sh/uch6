import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../state/auth_notifier.dart';
import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  attachApiInterceptors(dio, tokenProvider: tokenProvider);
  return dio;
}

void attachRefreshInterceptor(Dio dio, AuthNotifier auth) {
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final skip = error.requestOptions.extra['skipAuthRefresh'] == true;
        if (skip || status != 401 || path.contains('/auth-')) {
          return handler.next(error);
        }
        try {
          await auth.refreshTokens();
          final options = error.requestOptions;
          options.headers['Authorization'] = auth.accessToken;
          options.extra['skipAuthRefresh'] = true;
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (_) {
          await auth.logout();
          return handler.next(error);
        }
      },
    ),
  );
}

void attachApiInterceptors(Dio dio, {String? Function()? tokenProvider}) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = token;
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint(
            '[API] ${response.requestOptions.method} '
            '${response.requestOptions.uri} → $status',
          );
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );
}

Map<String, dynamic> listQuery({
  required String search,
  required String sortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
  Map<String, dynamic> extra = const {},
}) {
  final params = <String, dynamic>{
    'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
    'page': page,
    'size': size,
    ...extra,
  };
  if (search == '__fail__') {
    params['__fail'] = 500;
  } else if (search == '__delay__') {
    params['__delay'] = 1500;
  } else if (search.trim().isNotEmpty) {
    params['search'] = search.trim();
  }
  if (includeDeleted) params['includeDeleted'] = true;
  return params;
}
