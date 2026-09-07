import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/LearningReport/LearningReportService.dart';

import '../helpers/helpers.dart';

/// LearningReportService 계약 테스트.
///
/// public 메서드는 [getLearningReport] 하나뿐이지만, 응답 구조가 4단 중첩
/// (weekly/monthly/total × trend/weakAreas, comparison, recommendations)이라
/// 어느 단계에서 필드가 빠지느냐에 따라 결과가 크게 달라진다.
void main() {
  setUpOnoTest();

  LearningReportService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return LearningReportService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  Map<String, dynamic> periodJson({
    String label = '이번 주',
    int reviewCount = 10,
  }) =>
      {
        'periodLabel': label,
        'startDate': '2026-08-25',
        'endDate': '2026-08-31',
        'noteWriteCount': 4,
        'notePracticeCount': 6,
        'reviewCount': reviewCount,
        'averageAccuracy': 0.75,
        'consecutiveLearningDays': 5,
        'averageStudyTimeMinutes': 32.5,
        'trend': [
          {'label': '월', 'reviewCount': 2},
        ],
        'weakAreas': [
          {'topic': '미적분', 'wrongCount': 3},
        ],
      };

  final fullReportJson = {
    'weekly': periodJson(label: '이번 주', reviewCount: 10),
    'monthly': periodJson(label: '이번 달', reviewCount: 40),
    'total': periodJson(label: '전체', reviewCount: 200),
    'weeklyComparison': {
      'basePeriod': '이번 주',
      'compareTo': '지난 주',
      'reviewCountChangeRate': 0.1,
      'averageAccuracyChangeRate': 0.05,
      'consecutiveLearningDaysChangeRate': 0.2,
      'averageStudyTimeChangeRate': -0.1,
    },
    'monthlyComparison': null,
    'recommendations': {
      'strengths': ['꾸준한 복습'],
      'gaps': ['미적분 취약'],
      'actions': ['미적분 문제 5개 더 풀기'],
      'nextWeekGoal': '주 20문제',
      'confidence': 0.8,
    },
  };

  group('getLearningReport', () {
    test('GET /api/learning-reports, baseDate 없이 호출하면 쿼리 파라미터가 없다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullReportJson));
      final report = await buildService(http).getLearningReport();

      expect(http.lastRequest.method, 'GET');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/learning-reports',
      );
      expect(http.lastRequest.queryParameters, isEmpty);
      expect(http.lastRequest.authorization, 'test-access-token');

      expect(report.weekly.periodLabel, '이번 주');
      expect(report.weekly.reviewCount, 10);
      expect(report.weekly.trend, hasLength(1));
      expect(report.weekly.weakAreas.first.topic, '미적분');
      expect(report.monthly.reviewCount, 40);
      expect(report.total.reviewCount, 200);
      expect(report.weeklyComparison?.reviewCountChangeRate, 0.1);
      expect(report.monthlyComparison, isNull);
      expect(report.recommendations.nextWeekGoal, '주 20문제');
    });

    test('baseDate 를 주면 yyyy-MM-dd 로 쿼리에 붙는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullReportJson));
      await buildService(http)
          .getLearningReport(baseDate: DateTime(2026, 9, 3));

      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/learning-reports?baseDate=2026-09-03',
      );
    });

    test('weeklyComparison/monthlyComparison 이 둘 다 null 이어도 크래시 없이 넘어간다',
        () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'weekly': periodJson(),
          'monthly': periodJson(),
          'total': periodJson(),
          'weeklyComparison': null,
          'monthlyComparison': null,
          'recommendations': fullReportJson['recommendations'],
        }),
      );
      final report = await buildService(http).getLearningReport();
      expect(report.weeklyComparison, isNull);
      expect(report.monthlyComparison, isNull);
    });

    test('trend/weakAreas 가 없으면 빈 목록으로 처리된다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({
          'weekly': {'periodLabel': '이번 주'},
          'monthly': {'periodLabel': '이번 달'},
          'total': {'periodLabel': '전체'},
          'recommendations': <String, dynamic>{},
        }),
      );
      final report = await buildService(http).getLearningReport();
      expect(report.weekly.trend, isEmpty);
      expect(report.weekly.weakAreas, isEmpty);
      expect(report.weekly.reviewCount, 0);
      expect(report.recommendations.strengths, isEmpty);
      expect(report.recommendations.confidence, 0);
    });

    // TODO(#174): 실제 버그. lib/Model/LearningReport/LearningReportResponseModel.dart:20-22,30
    // weekly/monthly/total/recommendations 는 각각 `LearningPeriodReport.fromJson(json['weekly'])`
    // 처럼 null 검사 없이 곧바로 fromJson 에 넘긴다. 이 키들 중 하나라도 응답에서
    // 빠지면 `json['weekly']` 가 null 이 되어 `Map<String, dynamic> json` 자리에 null 이
    // 들어가려다 TypeError 로 죽는다. weeklyComparison/monthlyComparison 만 null 체크가 있다.
    test(
      'weekly 키 자체가 빠지면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(
          apiEnvelope({
            'monthly': periodJson(),
            'total': periodJson(),
            'recommendations': fullReportJson['recommendations'],
          }),
        );
        await buildService(http).getLearningReport();
      },
      skip: '#174 에서 수정 예정',
    );

    // TODO(#174): 실제 버그. lib/Service/Api/LearningReport/LearningReportService.dart:26
    // `sendRequest(...) as Map<String, dynamic>` 캐스팅이라, 응답 본문이 비어
    // HttpService 가 null 을 돌려주면(204 등) `null as Map<String, dynamic>` 에서
    // TypeError 로 죽는다.
    test(
      '응답 본문이 비어 있으면(204) TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondWith(emptyResponse());
        await buildService(http).getLearningReport();
      },
      skip: '#174 에서 수정 예정',
    );

    test('400 + errorCode 는 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 6001, message: '잘못된 요청'),
      );
      await expectLater(
        buildService(http).getLearningReport(),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('errorCode 1000번대는 UnauthorizedException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 401, errorCode: 1001, message: '인증 실패'),
      );
      await expectLater(
        buildService(http).getLearningReport(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('500 이면 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http).getLearningReport(),
        throwsA(isA<ServerException>()),
      );
    });

    test('전송 실패는 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException(''));
      await expectLater(
        buildService(http).getLearningReport(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('실패 응답이 JSON 이 아니면 ParseException', () async {
      final http = TestHttpClient.respondWith(
        textResponse('오류', statusCode: 500),
      );
      await expectLater(
        buildService(http).getLearningReport(),
        throwsA(isA<ParseException>()),
      );
    });

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(fullReportJson));
      await expectLater(
        buildService(http, accessToken: null).getLearningReport(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });
  });
}
