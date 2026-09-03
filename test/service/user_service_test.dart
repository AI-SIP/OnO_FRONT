import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/User/UserService.dart';

import '../helpers/helpers.dart';

/// UserService 계약 테스트.
///
/// 소셜 로그인 토큰을 받아 서버로 넘기는 부분(signInWithGuest, signInWithMember)과
/// 그 뒤 유저 정보 CRUD 만 다룬다. `lib/Service/SocialLogin/`(Apple·Google·Kakao)은
/// 플랫폼 SDK 에 직접 붙어 있어 단위 테스트 대상에서 제외했다.
void main() {
  setUpOnoTest();

  UserService buildService(
    TestHttpClient http, {
    String? accessToken = 'test-access-token',
  }) {
    return UserService(
      httpService: HttpService(
        client: http.client,
        tokenProvider: buildMockTokenProvider(accessToken: accessToken),
      ),
    );
  }

  final userJson = {
    'userId': 1,
    'email': 'test@ono.local',
    'name': '기승민',
    'profileImageUrl': 'https://cdn.test/profile.png',
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-08-01T00:00:00Z',
    'attendanceLevel': 2,
    'attendancePoint': 10,
    'noteWriteLevel': 3,
    'noteWritePoint': 20,
    'problemPracticeLevel': 1,
    'problemPracticePoint': 0,
    'notePracticeLevel': 1,
    'notePracticePoint': 0,
    'totalStudyLevel': 5,
    'totalStudyCurrentPoint': 30,
    'totalStudyNextLevelThreshold': 50,
    'notificationEnabled': true,
  };

  group('signInWithGuest', () {
    test('POST /api/auth/signup/guest, 토큰 없이 요청한다', () async {
      final http =
          TestHttpClient.respondJson(apiEnvelope({'accessToken': 't'}));
      await buildService(http, accessToken: null).signInWithGuest();

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/auth/signup/guest',
      );
      expect(http.lastRequest.authorization, isNull);
    });

    test('500 이어도 requiredToken:false 라 토큰 검증과 무관하게 ServerException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http, accessToken: null).signInWithGuest(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('signInWithMember', () {
    test('POST /api/auth/signup/member, 모델의 toJson 이 그대로 전송되고 토큰이 없다',
        () async {
      final http =
          TestHttpClient.respondJson(apiEnvelope({'accessToken': 't'}));
      final model = UserRegisterModel(
        email: 'a@ono.local',
        name: '기승민',
        identifier: 'apple-id',
        platform: 'apple',
      );
      await buildService(http, accessToken: null).signInWithMember(model);

      expect(http.lastRequest.method, 'POST');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/auth/signup/member',
      );
      expect(http.lastRequest.authorization, isNull);
      expect(
        http.lastRequest.jsonBody,
        {
          'email': 'a@ono.local',
          'name': '기승민',
          'identifier': 'apple-id',
          'platform': 'apple',
          'password': '',
          'profileImageUrl': null,
        },
      );
    });

    test('userRegisterModel 이 null 이면 요청 없이 Exception', () async {
      await expectLater(
        buildService(TestHttpClient.respondJson(apiEnvelope(null)))
            .signInWithMember(null),
        throwsA(isA<Exception>()),
      );
    });

    test('가입 실패(400+errorCode)는 BadRequestException', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 400, errorCode: 4001, message: '이미 가입된 사용자'),
      );
      final model = UserRegisterModel(identifier: 'x', platform: 'kakao');
      await expectLater(
        buildService(http, accessToken: null).signInWithMember(model),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('fetchUserInfo', () {
    test('GET /api/users, Authorization 헤더가 붙는다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(userJson));
      final user = await buildService(http).fetchUserInfo();

      expect(http.lastRequest.method, 'GET');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/users');
      expect(http.lastRequest.authorization, 'test-access-token');
      expect(user.userId, 1);
      expect(user.name, '기승민');
      expect(user.totalStudyLevel, 5);
    });

    test('필수 필드가 없어도 레벨/포인트 류는 기본값으로 채워져 크래시 없이 넘어간다', () async {
      final http = TestHttpClient.respondJson(
        apiEnvelope({'userId': 2, 'email': null, 'name': null}),
      );
      final user = await buildService(http).fetchUserInfo();
      expect(user.userId, 2);
      expect(user.attendanceLevel, 1);
      expect(user.totalStudyLevel, 0);
      expect(user.notificationEnabled, isTrue);
    });

    // TODO(#174): 실제 버그. lib/Model/User/UserInfoModel.dart:49
    // userId 가 응답에서 아예 빠지면(키 자체가 없음) json['userId'] 가 null 이 되어
    // non-nullable int 필드에 null 을 대입하려다 TypeError 로 죽는다.
    test(
      'userId 키 자체가 없으면 TypeError 로 죽는다',
      () async {
        final http = TestHttpClient.respondJson(
          apiEnvelope({'email': 'a@ono.local'}),
        );
        await buildService(http).fetchUserInfo();
      },
      skip: '#174 에서 수정 예정',
    );

    test('토큰이 없으면 요청 없이 UnauthorizedException', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(userJson));
      await expectLater(
        buildService(http, accessToken: null)
            .fetchUserInfo(showErrorSnackBar: false),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(http.callCount, 0);
    });

    test('500 이면 ServerException, showErrorSnackBar:false 로 넘길 수 있다', () async {
      final http = TestHttpClient.respondWith(
        errorResponse(statusCode: 500, message: '서버 오류'),
      );
      await expectLater(
        buildService(http).fetchUserInfo(showErrorSnackBar: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('전송 실패는 NetworkException', () async {
      final http = TestHttpClient.throwing(const SocketException(''));
      await expectLater(
        buildService(http).fetchUserInfo(showErrorSnackBar: false),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('updateUserProfile', () {
    test('PATCH /api/users, 모델의 toJson 이 그대로 전송된다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      final model = UserRegisterModel(name: '변경된 이름');
      await buildService(http).updateUserProfile(model);

      expect(http.lastRequest.method, 'PATCH');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/users');
      expect(http.lastRequest.jsonBody!['name'], '변경된 이름');
    });

    test('모델이 null 이면 body 없이 요청한다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).updateUserProfile(null);

      expect(http.lastRequest.jsonBody, isNull);
    });
  });

  group('updateUserProfileImage', () {
    late File tempImage;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('ono_test_');
      tempImage = File('${dir.path}/profile.png')
        ..writeAsBytesSync(const [137, 80, 78, 71]);
    });

    test('PATCH multipart /api/users/me/profile-image', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(userJson));
      final user =
          await buildService(http).updateUserProfileImage(tempImage.path);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/users/me/profile-image',
      );
      expect(http.lastRequest.contentType, contains('multipart/form-data'));
      expect(http.lastRequest.body, contains('name="profileImage"'));
      expect(user.userId, 1);
    });
  });

  group('updateUserProfileImageUrl', () {
    test('PATCH /api/users/me/profile-image-url, url 을 body 로 보낸다', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(userJson));
      final user = await buildService(http)
          .updateUserProfileImageUrl('https://cdn.test/new.png');

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/users/me/profile-image-url',
      );
      expect(
        http.lastRequest.jsonBody,
        {'profileImageUrl': 'https://cdn.test/new.png'},
      );
      expect(user.userId, 1);
    });
  });

  group('deleteUserProfileImage', () {
    test('DELETE /api/users/me/profile-image', () async {
      final http = TestHttpClient.respondJson(apiEnvelope(userJson));
      final user = await buildService(http).deleteUserProfileImage();

      expect(http.lastRequest.method, 'DELETE');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/users/me/profile-image',
      );
      expect(user.userId, 1);
    });
  });

  group('updateNotificationSettings', () {
    test('PATCH /api/users/notification-settings, bool 을 body 로 보낸다', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).updateNotificationSettings(false);

      expect(http.lastRequest.method, 'PATCH');
      expect(
        http.lastRequest.url.toString(),
        '$testBaseUrl/api/users/notification-settings',
      );
      expect(http.lastRequest.jsonBody, {'notificationEnabled': false});
    });
  });

  group('logoutAccount / deleteAccount', () {
    test('logoutAccount: POST /api/auth/logout', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).logoutAccount();

      expect(http.lastRequest.method, 'POST');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/auth/logout');
      expect(http.lastRequest.authorization, 'test-access-token');
    });

    test('deleteAccount: DELETE /api/users', () async {
      final http = TestHttpClient.respondWith(emptyResponse());
      await buildService(http).deleteAccount();

      expect(http.lastRequest.method, 'DELETE');
      expect(http.lastRequest.url.toString(), '$testBaseUrl/api/users');
    });
  });
}
