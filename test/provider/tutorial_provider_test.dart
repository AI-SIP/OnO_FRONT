// TutorialProvider 상태 전이 테스트.
//
// 튜토리얼은 idle → intro → running → outro → idle 로 순환하는 상태 기계다.
// 각 전이가 실제로 조건을 지키는지(잘못된 상태에서 부르면 무시하는지),
// 마지막 스텝 이후 outro 로 넘어가는지, complete/skip 이후 idle 로 확실히
// 리셋되는지를 본다. FirebaseAnalytics 를 매 전이마다 fire-and-forget 으로
// 호출하므로 support/provider_test_env 스텁이 필수다(없으면 전이 도중
// 예외가 나서 notifyListeners 까지 가지도 못한다).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/TutorialProvider.dart';
import 'package:ono/Screen/Tutorial/TutorialStep.dart';
import 'package:ono/Screen/Tutorial/TutorialStorage.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

class MockTutorialStorage extends Mock implements TutorialStorage {}

void main() {
  setUpOnoTest();

  setUpAll(setUpProviderTestEnv);

  late MockTutorialStorage storage;
  late TutorialProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    storage = MockTutorialStorage();
    provider = TutorialProvider(storage: storage);
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  group('초기 상태', () {
    test('idle 상태이고 화면에 보이지 않는다', () {
      expect(provider.status, TutorialStatus.idle);
      expect(provider.isVisible, isFalse);
      expect(provider.currentStepIndex, 0);
    });
  });

  group('showAutoIntroIfNeeded', () {
    test('가입 직후(30분 이내)면 intro 를 띄운다', () async {
      when(() => storage.isCompleted(1)).thenAnswer((_) async => false);
      final userInfo = UserInfoModel(
        userId: 1,
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: true,
      );

      expect(provider.status, TutorialStatus.intro);
      expect(provider.isIntro, isTrue);
      expect(notified.count, greaterThan(0));
    });

    test('첫 로그인이 아니면 띄우지 않는다', () async {
      final userInfo = UserInfoModel(userId: 1, createdAt: DateTime.now());

      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: false,
      );

      expect(provider.status, TutorialStatus.idle);
      verifyNever(() => storage.isCompleted(any()));
    });

    test('가입한 지 오래됐으면(30분 초과) 띄우지 않는다', () async {
      final userInfo = UserInfoModel(
        userId: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: true,
      );

      expect(provider.status, TutorialStatus.idle);
    });

    test('이미 완료한 사용자면 띄우지 않는다', () async {
      when(() => storage.isCompleted(1)).thenAnswer((_) async => true);
      final userInfo = UserInfoModel(
        userId: 1,
        createdAt: DateTime.now(),
      );

      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: true,
      );

      expect(provider.status, TutorialStatus.idle);
    });

    test('이미 idle 이 아니면(다른 튜토리얼이 떠 있으면) 다시 띄우지 않는다', () async {
      provider.showReplayIntro(1);
      expect(provider.status, TutorialStatus.intro);

      final userInfo = UserInfoModel(userId: 2, createdAt: DateTime.now());
      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: true,
      );

      // source 가 replay 로 남아있어야 한다 (덮어써지지 않음).
      expect(provider.source, TutorialLaunchSource.settingsReplay);
    });
  });

  group('start / next / previous', () {
    test('intro 상태에서만 start 가 먹힌다', () {
      provider.start(); // idle 상태 -> 무시

      expect(provider.status, TutorialStatus.idle);
    });

    test('start 하면 running 으로 바뀌고 첫 스텝부터 시작한다', () {
      provider.showReplayIntro(1);

      provider.start();

      expect(provider.status, TutorialStatus.running);
      expect(provider.currentStepIndex, 0);
    });

    test('next 를 마지막 스텝까지 부르면 outro 로 넘어간다', () async {
      provider.showReplayIntro(1);
      provider.start();
      final lastIndex = tutorialSteps.length - 1;

      for (var i = 0; i < lastIndex; i++) {
        await provider.next();
      }
      expect(provider.status, TutorialStatus.running);
      expect(provider.currentStepIndex, lastIndex);

      await provider.next(); // 마지막 스텝에서 한 번 더

      expect(provider.status, TutorialStatus.outro);
    });

    test('previous 는 outro 에서 부르면 마지막 스텝의 running 으로 돌아간다', () async {
      provider.showReplayIntro(1);
      provider.start();
      for (var i = 0; i < tutorialSteps.length - 1; i++) {
        await provider.next();
      }
      await provider.next(); // outro

      provider.previous();

      expect(provider.status, TutorialStatus.running);
      expect(provider.currentStepIndex, tutorialSteps.length - 1);
    });

    test('previous 는 첫 스텝(index 0)에서는 더 못 간다', () {
      provider.showReplayIntro(1);
      provider.start();

      provider.previous();

      expect(provider.currentStepIndex, 0);
      expect(provider.status, TutorialStatus.running);
    });
  });

  group('skip / complete', () {
    test('skip 하면 idle 로 리셋되고, firstSignup 출처면 완료 처리를 저장한다', () async {
      when(() => storage.isCompleted(1)).thenAnswer((_) async => false);
      final userInfo = UserInfoModel(
        userId: 1,
        createdAt: DateTime.now(),
      );
      await provider.showAutoIntroIfNeeded(
        userInfo: userInfo,
        isFirstLogin: true,
      );
      when(() => storage.markCompleted(1)).thenAnswer((_) async {});

      await provider.skip();

      expect(provider.status, TutorialStatus.idle);
      expect(provider.source, isNull);
      verify(() => storage.markCompleted(1)).called(1);
    });

    test('설정에서 다시보기(settingsReplay) 로 시작했으면 완료 저장을 하지 않는다', () async {
      provider.showReplayIntro(1);

      await provider.complete();

      expect(provider.status, TutorialStatus.idle);
      verifyNever(() => storage.markCompleted(any()));
    });
  });
}
