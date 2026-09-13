// AchievementProvider 가 훈장판과 **축하거리**를 어떻게 다루는지 잠근다.
//
// 이 파일의 절반은 `newlyEarned` 이야기다. 서버는 새로 받은 훈장을 그 응답
// 한 번에만 실어 주고, 다음 조회에서는 그냥 `earned: true` 일 뿐이다. 앱이
// 그 한 번을 놓치면 축하가 영영 사라진다. 쌓고, 적어 두고, 본 뒤에 지우는
// 세 가지가 전부 여기서 잠긴다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Achievement/AchievementBoardModel.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Provider/AchievementProvider.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  UserInfoModel someone() =>
      UserInfoModel(userId: 7, createdAt: DateTime.now());

  AchievementProvider build({
    FakeAchievementService? service,
    FakeAchievementCelebrationStore? store,
  }) {
    return AchievementProvider(
      service: service ?? FakeAchievementService(),
      store: store ?? FakeAchievementCelebrationStore(),
    );
  }

  group('조회', () {
    test('받으면 열두 개를 들고 있는다', () async {
      final provider = build();

      expect(await provider.load(), isTrue);
      expect(provider.state, AchievementLoadState.ready);
      expect(provider.achievements, hasLength(12));
      expect(provider.total, 12);
      expect(provider.earnedCount, 3);
      expect(provider.isEmpty, isFalse);
    });

    test('서버가 준 순서를 그대로 들고 있는다', () async {
      final provider = build();
      await provider.load();

      expect(
        provider.achievements.map((item) => item.key).toList(),
        AchievementMockData.keys,
      );
    });

    test('한 번도 못 받으면 실패로 남는다', () async {
      final provider = build(service: FakeAchievementService(failLoad: true));

      expect(await provider.load(), isFalse);
      expect(provider.state, AchievementLoadState.failed);
      expect(provider.isEmpty, isTrue);
    });

    test('받은 뒤의 실패는 들고 있던 것을 지우지 않는다', () async {
      // 잠깐 끊겼다고 받은 훈장이 사라지는 편이 더 이상하다.
      final service = FakeAchievementService();
      final provider = build(service: service);
      await provider.load();

      service.failLoad = true;
      expect(await provider.load(), isFalse);

      expect(provider.state, AchievementLoadState.ready);
      expect(provider.achievements, hasLength(12));
    });

    test('겹쳐 부르면 조회는 한 번만 나간다', () async {
      // 로그인 직후와 훈장 화면 진입이 겹칠 수 있다.
      final service = FakeAchievementService();
      final provider = build(service: service);

      await Future.wait([provider.load(), provider.load()]);

      expect(service.loadCount, 1);
    });
  });

  group('새로 받은 훈장', () {
    test('받는 순간 쌓이고 기기에 적힌다', () async {
      final store = FakeAchievementCelebrationStore();
      final provider = build(store: store);

      await provider.load();

      expect(provider.hasNews, isTrue);
      expect(provider.pendingCelebration, {'perfect_month'});
      // 알리기 전에 앱이 내려가도 남아 있어야 한다.
      expect(store.stored, {'perfect_month'});
    });

    test('다음 조회가 빈 배열을 줘도 쌓아 둔 것은 안 지워진다', () async {
      // 진짜 서버가 그렇다. 새로 받은 것은 그 응답 한 번에만 실린다. 두 번째
      // 조회의 빈 배열로 덮어쓰면, 로그인 직후에 받은 축하가 훈장 화면을 여는
      // 순간 사라진다.
      final service = FakeAchievementService();
      final provider = build(service: service);

      await provider.load();
      await provider.load();

      expect(service.loadCount, 2);
      expect(provider.pendingCelebration, {'perfect_month'});
    });

    test('여러 번에 걸쳐 받은 것이 합쳐진다', () async {
      final service = FakeAchievementService(
        board: AchievementBoardModel(
          achievements: AchievementMockData.achievements,
          newlyEarned: const ['perfect_month'],
        ),
      );
      final provider = build(service: service);
      await provider.load();

      service.board = AchievementBoardModel(
        achievements: AchievementMockData.achievements,
        newlyEarned: const ['flawless'],
      );
      service.newsOnlyOnce = false;
      await provider.load();

      expect(provider.pendingCelebration, {'perfect_month', 'flawless'});
    });

    test('기기에 적어 둔 것을 다시 켰을 때 되살린다', () async {
      // 축하를 띄우기 전에 앱이 내려간 경우다. 이게 없으면 서른 날을 채우고
      // 받은 개근 훈장이 조용히 사라진다.
      final store = FakeAchievementCelebrationStore({'organizer'});
      final provider = build(store: store);

      await provider.restore();

      expect(provider.hasNews, isTrue);
      expect(provider.pendingCelebration, {'organizer'});
    });

    test('되살리기는 한 번만 읽는다', () async {
      final store = FakeAchievementCelebrationStore({'organizer'});
      final provider = build(store: store);

      await provider.restore();
      provider.consumeCelebration();
      await provider.restore();

      // 두 번째 restore 가 저장소를 다시 읽었다면 이미 본 축하가 되살아난다.
      expect(provider.hasNews, isFalse);
    });

    test('꺼내 쓰면 메모리도 기기도 비워진다', () async {
      final store = FakeAchievementCelebrationStore();
      final provider = build(store: store);
      await provider.load();

      expect(provider.consumeCelebration(), ['perfect_month']);

      expect(provider.hasNews, isFalse);
      expect(provider.pendingCelebration, isEmpty);
      expect(store.stored, isEmpty);
    });

    test('꺼낼 것이 없으면 저장소를 건드리지 않는다', () async {
      final store = FakeAchievementCelebrationStore();
      final provider = build(
        service: FakeAchievementService(
          board: AchievementBoardModel(
            achievements: AchievementMockData.achievements,
            newlyEarned: const [],
          ),
        ),
        store: store,
      );
      await provider.load();

      expect(provider.consumeCelebration(), isEmpty);
      expect(store.writeCount, 0);
    });
  });

  group('로그인 생애주기', () {
    test('유저 정보를 받으면 한 번 채운다', () async {
      final service = FakeAchievementService();
      final provider = build(service: service);

      await provider.syncWithUser(someone());

      expect(service.loadCount, 1);
      expect(provider.achievements, hasLength(12));
    });

    test('유저 정보가 다시 와도 또 묻지 않는다', () async {
      // 유저 정보는 문제를 하나 풀 때마다도 다시 읽힌다. 그때마다 열두 가지
      // 조건을 서버가 다시 세게 하면 요청만 는다.
      final service = FakeAchievementService();
      final provider = build(service: service);

      await provider.syncWithUser(someone());
      await provider.syncWithUser(someone());
      await provider.syncWithUser(someone());

      expect(service.loadCount, 1);
    });

    test('정보가 null 이면 아무것도 하지 않는다', () async {
      // 유저 정보 조회가 잠깐 실패해도 null 이 온다. 그걸 로그아웃으로 보면 안 된다.
      final service = FakeAchievementService();
      final provider = build(service: service);

      await provider.syncWithUser(null);

      expect(service.loadCount, 0);
      expect(provider.state, AchievementLoadState.idle);
    });

    test('비우면 훈장도 축하거리도 기기에서까지 지운다', () async {
      // 다른 계정으로 로그인한 첫 화면에 앞 사람이 받은 훈장의 축하가 뜨면 안 된다.
      final store = FakeAchievementCelebrationStore();
      final provider = build(store: store);
      await provider.load();

      provider.clear();
      // clear 는 저장소 쓰기를 기다리지 않는다. 한 틱 넘긴다.
      await Future<void>.delayed(Duration.zero);

      expect(provider.isEmpty, isTrue);
      expect(provider.state, AchievementLoadState.idle);
      expect(provider.hasNews, isFalse);
      expect(store.stored, isEmpty);
    });
  });

  group('알림', () {
    test('조회 한 번에 시작과 끝을 알린다', () async {
      final provider = build();
      final notified = NotifyRecorder();
      provider.addListener(notified.call);

      await provider.load();

      expect(notified.count, greaterThanOrEqualTo(2));
    });
  });
}
