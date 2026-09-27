import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/StudyCalendar/StudyCalendarService.dart';

import '../helpers/helpers.dart';

/// StudyCalendarService 계약 테스트.
void main() {
  setUpOnoTest();

  StudyCalendarService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return StudyCalendarService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  final calendarJson = {
    'year': 2026,
    'month': 9,
    'currentStreak': 3,
    'bestStreak': 7,
    'thisMonthStudyDays': 10,
    'records': [
      {
        'date': '2026-09-01',
        'hasStudied': true,
        'reviewCount': 5,
        'noteWriteCount': 2,
        'studyMinutes': 30,
        'reviewedItems': ['problem_1', 'problem_2'],
        'moodEmojiKey': 'happy',
      },
    ],
  };

  group('getStudyCalendar', () {
    test('GET /api/learning-calendar, year/month 가 쿼리로 붙는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(calendarJson));
      final calendar =
          await buildService(http).getStudyCalendar(year: 2026, month: 9);

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/learning-calendar?year=2026&month=9',
      );
      expect(http.lastRequest.authorization, 'test-access-token');

      expect(calendar.year, 2026);
      expect(calendar.month, 9);
      expect(calendar.currentStreak, 3);
      expect(calendar.records, hasLength(1));
      expect(calendar.recordFor(1)?.hasStudied, isTrue);
      expect(calendar.recordFor(1)?.intensityLevel, 2);
    });

    test('필수 필드가 통째로 빠져도 크래시 없이 0/빈 값으로 채워진다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(<String, dynamic>{}));
      final calendar =
          await buildService(http).getStudyCalendar(year: 2026, month: 9);

      expect(calendar.year, 0);
      expect(calendar.records, isEmpty);
    });

    test('레코드 안의 date 가 없으면 DateTime(0) 으로 대체되어 recordFor 가 못 찾는다', () async {
      // DailyStudyRecord.fromJson 은 date 가 없으면 DateTime(0) 을 쓴다.
      // recordFor(day) 는 이 레코드와 절대 매치되지 않아 화면에 표시되지 않는다.
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'year': 2026,
          'month': 9,
          'records': [
            {'hasStudied': true, 'reviewCount': 1},
          ],
        }),
      );
      final calendar =
          await buildService(http).getStudyCalendar(year: 2026, month: 9);
      expect(calendar.records, hasLength(1));
      expect(calendar.recordFor(1), isNull);
    });

    test('showErrorSnackBar:false 로 넘기면 400+errorCode 에도 BadRequestException',
        () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 5001, message: '잘못된 요청'),
      );
      await expectLater(
        buildService(http)
            .getStudyCalendar(year: 2026, month: 9, showErrorSnackBar: false),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('errorCode 1000번대는 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1001, message: '인증 실패'),
      );
      await expectLater(
        buildService(http)
            .getStudyCalendar(year: 2026, month: 9, showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http)
            .getStudyCalendar(year: 2026, month: 9, showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('전송 실패는 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException(''));
      await expectLater(
        buildService(http)
            .getStudyCalendar(year: 2026, month: 9, showErrorSnackBar: false),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답이 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('오류', statusCode: 500),
      );
      await expectLater(
        buildService(http)
            .getStudyCalendar(year: 2026, month: 9, showErrorSnackBar: false),
        throwsA(isA<ParseException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(calendarJson));
      await expectLater(
        buildService(http, accessToken: null).getStudyCalendar(
          year: 2026,
          month: 9,
          showErrorSnackBar: false,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });

  group('updateMoodEmoji', () {
    test('PATCH /api/learning-calendar/mood, 날짜는 yyyy-MM-dd 로 포맷된다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).updateMoodEmoji(
        date: DateTime(2026, 9, 3),
        emojiKey: 'happy',
      );

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/learning-calendar/mood',
      );
      expect(
        http.lastRequest.jsonBody,
        {'date': '2026-09-03', 'emojiKey': 'happy'},
      );
    });

    test('한 자리 월/일도 0으로 패딩된다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).updateMoodEmoji(
        date: DateTime(2026, 1, 5),
        emojiKey: 'sad',
      );

      expect(http.lastRequest.jsonBody!['date'], '2026-01-05');
    });

    test('showErrorSnackBar:false 로 넘기면 실패해도 스낵바 없이 예외만 던진다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 5002, message: '잘못된 감정 키'),
      );
      await expectLater(
        buildService(http).updateMoodEmoji(
          date: DateTime(2026, 9, 3),
          emojiKey: 'invalid',
          showErrorSnackBar: false,
        ),
        throwsA(isA<BadRequestException>()),
      );
    });
  });
}
