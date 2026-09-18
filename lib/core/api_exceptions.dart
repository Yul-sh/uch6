import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  String get kindLabel => switch (this) {
    NetworkException() => 'Сетевая ошибка (нет соединения, таймаут или CORS)',
    UnauthorizedException() => '401 — не аутентифицирован',
    ForbiddenException() => '403 — недостаточно прав',
    NotFoundException() => '404 — не найдено',
    ConflictException() => '409 — конфликт',
    ValidationException() => '422 — ошибка валидации',
    RequestCancelledException() => 'Запрос отменён',
    ServerException() =>
      statusCode == null ? 'Ошибка сервера' : '$statusCode — ошибка сервера',
  };

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.'])
    : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.'])
    : super(statusCode: 404);
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {super.statusCode = 409});
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(
    super.message,
    this.errors, {
    super.statusCode = 422,
  });
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException() : super('Запрос отменён.');
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  Map<String, String> fieldErrors = const {};
  if (body is Map && body['data'] is Map) {
    fieldErrors = (body['data'] as Map).map((k, v) {
      if (v is Map && v['message'] != null) {
        return MapEntry('$k', '${v['message']}');
      }
      return MapEntry('$k', '$v');
    });
  } else if (body is Map && body['errors'] is Map) {
    fieldErrors = (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'));
  }
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    400 when fieldErrors.isNotEmpty => ValidationException(
      message ?? 'Ошибка валидации',
      fieldErrors,
      statusCode: 400,
    ),
    422 => ValidationException(message ?? 'Ошибка валидации', fieldErrors),
    _ => ServerException(
      message ?? 'Неизвестная ошибка (код $status).',
      status,
    ),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;
  if (e.type == DioExceptionType.cancel || CancelToken.isCancel(e)) {
    return const RequestCancelledException();
  }
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. '
      'Если сервер запущен, откройте консоль браузера и проверьте наличие ошибки CORS.',
    ),
    DioExceptionType.cancel => const RequestCancelledException(),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

Future<T> guardRead<T>(Future<T> Function() action) async {
  DioException? last;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      return await action();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || e.error is RequestCancelledException) {
        throw mapDioError(e);
      }
      last = e;
      final mapped = mapDioError(e);
      if (mapped is! NetworkException || attempt == 2) {
        throw mapped;
      }
      await Future<void>.delayed(Duration(milliseconds: 300 * (1 << attempt)));
    }
  }
  throw mapDioError(last!);
}

String loadErrorMessage(Object error) {
  if (error is ApiException) {
    return '${error.message}\n\n${error.kindLabel}';
  }
  return 'Не удалось загрузить данные: $error';
}
