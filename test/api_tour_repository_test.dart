import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_y/core/api_client.dart';
import 'package:fly_y/core/api_exceptions.dart';
import 'package:fly_y/models/tour.dart';
import 'package:fly_y/models/tour_query.dart';
import 'package:fly_y/repositories/api_tour_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.status = 200, this.body, this.errorType});

  final int status;
  final Object? body;
  final DioExceptionType? errorType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (errorType != null) {
      throw DioException(requestOptions: options, type: errorType!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio({int status = 200, Object? body, DioExceptionType? errorType}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      validateStatus: (code) => code != null && code < 500,
    ),
  );
  attachApiInterceptors(dio);
  dio.httpClientAdapter = _Adapter(
    status: status,
    body: body,
    errorType: errorType,
  );
  return dio;
}

void main() {
  test('Tour.fromJson читает и id, и вложенные объекты', () {
    final tour = Tour.fromJson({
      'id': 'abc123xyz45678',
      'title': 'Тест',
      'code': 'TY-1',
      'year': 2026,
      'durationDays': 7,
      'destination': {'id': 'dest0000000004', 'name': 'Рим'},
      'hotels': [
        {'id': 'hotel000000008'},
        {'id': 'hotel000000009'},
      ],
      'categories': [
        {'id': 'cat00000000002'},
      ],
      'seatsTotal': 10,
      'seatsAvailable': 3,
      'price': 100000,
    });
    expect(tour.destinationId, 'dest0000000004');
    expect(tour.hotelIds, ['hotel000000008', 'hotel000000009']);
    expect(tour.categoryIds, ['cat00000000002']);
  });

  test('find разбирает страницу с сервера', () async {
    final repo = ApiTourRepository(
      _dio(
        body: {
          'items': [
            {
              'id': 'abc123xyz45678',
              'title': 'Солнце',
              'code': 'TY-2024-001',
              'year': 2024,
              'durationDays': 7,
              'destinationId': 'dest0000000001',
              'hotelIds': ['hotel000000001'],
              'categoryIds': ['cat00000000001'],
              'seatsTotal': 40,
              'seatsAvailable': 12,
              'price': 89000,
            },
          ],
          'page': 1,
          'size': 10,
          'total': 22,
        },
      ),
    );
    final page = await repo.find(const TourQuery());
    expect(page.total, 22);
    expect(page.items.single.title, 'Солнце');
  });

  test('create при 422 даёт ValidationException с ошибкой поля code', () async {
    final repo = ApiTourRepository(
      _dio(
        status: 422,
        body: {
          'message': 'Ошибка валидации',
          'errors': {'code': 'Код тура уже занят'},
        },
      ),
    );
    await expectLater(
      repo.create(
        const Tour(
          id: '',
          title: 'Дубль',
          code: 'TY-2024-001',
          year: 2026,
          durationDays: 7,
          destinationId: 'dest0000000001',
          hotelIds: ['hotel000000001'],
          categoryIds: ['cat00000000001'],
          seatsTotal: 10,
          seatsAvailable: 10,
          price: 10000,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['code'],
          'code',
          'Код тура уже занят',
        ),
      ),
    );
  });

  test('book при 409 даёт ConflictException', () async {
    final repo = ApiTourRepository(
      _dio(status: 409, body: {'message': 'Нет свободных мест на этот тур.'}),
    );
    await expectLater(
      repo.book('abc123xyz45678'),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          contains('свободных мест'),
        ),
      ),
    );
  });

  test('connectionError превращается в NetworkException', () async {
    final repo = ApiTourRepository(
      _dio(errorType: DioExceptionType.connectionError),
    );
    await expectLater(
      repo.find(const TourQuery()),
      throwsA(isA<NetworkException>()),
    );
  });
}
