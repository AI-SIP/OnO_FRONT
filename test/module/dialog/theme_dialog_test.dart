// 테마 고르는 창 위젯 테스트.
//
// 이 창이 지켜야 하는 약속은 넷이다.
//   1. 열이 능력치라는 것이 드러날 것 (이름·아이콘·지금 레벨)
//   2. 행이 단계라는 것이 드러날 것 (기본 / Lv.3 … Lv.15)
//   3. 잠긴 칸이 **무엇을 얼마나 올려야 열리는지** 칸에서 바로 읽힐 것
//   4. 잠긴 칸은 눌러도 골라지지 않을 것 (해금 규칙은 화면이 못 바꾼다)
//
// 세로가 빡빡한 화면이라 작은 폰·태블릿·글자 키운 기기에서 넘치지 않는지도
// 같이 잠근다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Module/Dialog/ThemeDialog.dart';
import 'package:ono/Module/Motion/TossDialog.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Module/Theme/ThemeLockManager.dart';
import 'package:ono/Provider/UserProvider.dart';

import '../../helpers/helpers.dart';

class _FakeUserProvider extends Mock implements UserProvider {}

/// 창이 읽는 것은 `userInfoModel` 하나뿐이다. 진짜 Provider 는 서버를 거쳐야
/// 값이 차므로 값을 바로 들고 있는 가짜를 쓴다.
_FakeUserProvider _userProvider(UserInfoModel? info) {
  final provider = _FakeUserProvider();
  when(() => provider.isLoggedIn).thenReturn(LoginStatus.login);
  when(() => provider.userInfoModel).thenReturn(info);
  when(() => provider.addListener(any())).thenReturn(null);
  when(() => provider.removeListener(any())).thenReturn(null);
  when(() => provider.dispose()).thenReturn(null);
  return provider;
}

/// 출석 4 · 오답노트 1 · 문제 복습 7 · 복습 세트 1.
///
/// 열마다 올라온 높이가 달라야 트랙이 제 구실을 하는지 볼 수 있다. 이 유저의
/// 열린 칸은 일곱(첫 행 넷 + 출석 Lv.3 + 문제 복습 Lv.3·Lv.6)이고 나머지
/// 열일곱은 잠겨 있다.
UserInfoModel _user({
  int attendance = 4,
  int noteWrite = 1,
  int problemPractice = 7,
  int notePractice = 1,
}) {
  return UserInfoModel(
    userId: 1,
    name: '테스터',
    attendanceLevel: attendance,
    noteWriteLevel: noteWrite,
    problemPracticeLevel: problemPractice,
    notePracticeLevel: notePractice,
  );
}

void main() {
  setUpOnoWidgetTest();

  // ThemeHandler 는 생성자에서 SecureStorage 를 읽고 색을 바꿀 때 거기에 쓴다.
  // 스텁 저장소는 파일 하나에 한 벌이라, 앞 테스트에서 적용한 색이 다음
  // 테스트의 ThemeHandler 로 새어 들어온다. 테스트마다 비워 둔다.
  setUp(stubSecureStorage);

  /// 적용을 누른 뒤 창이 닫히기까지.
  ///
  /// 바뀐 색을 한 박자 보여 주고 닫으므로 그 사이를 넘겨 줘야 한다.
  Future<void> tapApply(WidgetTester tester) async {
    await tester.tap(find.text('적용하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  /// 실제 호출 자리와 같게 버튼을 눌러 창을 띄운다. 그래야 취소·적용이
  /// 진짜로 창을 닫는지 볼 수 있다.
  Future<ThemeHandler> pumpThemeDialog(
    WidgetTester tester, {
    UserInfoModel? userInfo,

    /// 로그인 전처럼 유저 정보가 아예 없는 경우.
    bool withoutUserInfo = false,
    Size surfaceSize = OnoSurface.phone,
    double textScale = 1.0,
  }) async {
    if (textScale != 1.0) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    final themeHandler = ThemeHandler();

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showTossDialog(
                context: context,
                builder: (_) => ThemeDialog(),
              ),
              child: const Text('창 열기'),
            ),
          ),
        ),
      ),
      userProvider: _userProvider(
        withoutUserInfo ? null : (userInfo ?? _user()),
      ),
      themeHandler: themeHandler,
      surfaceSize: surfaceSize,
    );

    await tester.tap(find.text('창 열기'));
    await tester.pumpAndSettle();

    return themeHandler;
  }

  group('열이 능력치라는 것이 드러난다', () {
    testWidgets('능력치 넷의 이름이 열 머리에 선다', (tester) async {
      await pumpThemeDialog(tester);

      expect(find.text('출석'), findsOneWidget);
      expect(find.text('오답노트'), findsOneWidget);
      expect(find.text('문제 복습'), findsOneWidget);
      expect(find.text('복습 세트'), findsOneWidget);
    });

    testWidgets('지금 내 능력치 레벨이 열 머리에 붙는다', (tester) async {
      await pumpThemeDialog(tester);

      expect(find.text('Lv.4'), findsOneWidget); // 출석
      expect(find.text('Lv.7'), findsOneWidget); // 문제 복습
      expect(find.text('Lv.1'), findsNWidgets(2)); // 오답노트, 복습 세트
    });

    testWidgets('유저 정보가 없으면 레벨을 0 으로 적는다', (tester) async {
      // 잠금 판정도 같은 기준이라 첫 행 넷만 열려 있어야 한다.
      await pumpThemeDialog(tester, withoutUserInfo: true);

      expect(find.text('Lv.0'), findsNWidgets(4));
      // 단계 이름 하나 + 둘째 행 네 칸이 전부 잠김.
      expect(find.text('Lv.3'), findsNWidgets(5));
    });
  });

  group('행이 단계라는 것이 드러난다', () {
    testWidgets('격자 왼쪽에 단계 이름 여섯이 선다', (tester) async {
      await pumpThemeDialog(tester);

      expect(find.text('기본'), findsOneWidget);
      for (final label in ['Lv.3', 'Lv.6', 'Lv.9', 'Lv.12', 'Lv.15']) {
        expect(find.text(label), findsWidgets, reason: '$label 단계가 없다');
      }
    });

    testWidgets('24칸이 모두 그려진다', (tester) async {
      await pumpThemeDialog(tester);

      for (var index = 0; index < ThemeLockManager.themeCount; index++) {
        expect(
          find.byKey(ThemeDialog.cellKey(index)),
          findsOneWidget,
          reason: '$index 번 칸이 없다',
        );
      }
    });
  });

  group('잠긴 칸에 조건이 보인다', () {
    testWidgets('잠긴 칸마다 필요한 레벨이 칸 안에 적혀 있다', (tester) async {
      await pumpThemeDialog(tester);

      // 단계 이름 하나 + 그 행에서 잠긴 칸의 수.
      // 출석 4 / 오답노트 1 / 문제 복습 7 / 복습 세트 1 이므로
      // Lv.3 행은 둘, Lv.6 행은 셋, Lv.9 위로는 넷이 잠겨 있다.
      expect(find.text('Lv.3'), findsNWidgets(1 + 2));
      expect(find.text('Lv.6'), findsNWidgets(1 + 3));
      expect(find.text('Lv.9'), findsNWidgets(1 + 4));
      expect(find.text('Lv.12'), findsNWidgets(1 + 4));
      expect(find.text('Lv.15'), findsNWidgets(1 + 4));
    });

    testWidgets('잠긴 칸을 누르면 위쪽 판이 그 조건으로 바뀐다', (tester) async {
      await pumpThemeDialog(tester);

      // 출석 열(0)의 Lv.9 행(3) = 시안.
      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(3, 0))),
      );
      await tester.pumpAndSettle();

      expect(find.text('아직 잠긴 색'), findsOneWidget);
      expect(find.text('시안'), findsOneWidget);
      expect(find.text('출석 Lv.9 필요 · 지금 Lv.4'), findsOneWidget);
    });

    testWidgets('이름이 긴 능력치도 조건을 열 머리와 같은 이름으로 부른다', (tester) async {
      // 판에서는 '복습 세트 복습' 이 아니라 열 머리와 같은 '복습 세트' 다.
      // 긴 이름을 쓰면 좁은 폭에서 두 줄이 되고, 그때 판이 커지면서 격자가
      // 밀린다.
      await pumpThemeDialog(tester);

      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(5, 3))),
      );
      await tester.pumpAndSettle();

      expect(find.text('복습 세트 Lv.15 필요 · 지금 Lv.1'), findsOneWidget);
    });

    testWidgets('잠긴 칸은 눌러도 골라지지 않는다', (tester) async {
      final themeHandler = await pumpThemeDialog(tester);

      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(5, 3))),
      );
      await tester.pumpAndSettle();
      await tapApply(tester);

      // 처음 색(연핑크) 그대로다.
      expect(themeHandler.primaryColor, ThemeLockManager.getThemeColor(0));
    });
  });

  group('고르고 적용하기', () {
    testWidgets('열린 칸을 누르면 위쪽 판이 그 색과 출처를 보여 준다', (tester) async {
      await pumpThemeDialog(tester);

      // 출석 열의 Lv.3 행 = 빨간색. 출석 4 라서 열려 있다.
      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(1, 0))),
      );
      await tester.pumpAndSettle();

      expect(find.text('고른 색'), findsOneWidget);
      expect(find.text('빨간색'), findsOneWidget);
    });

    testWidgets('열린 색에는 이름 밑에 설명을 붙이지 않는다', (tester) async {
      // 어느 레벨에서 열었는지는 이미 지난 일이라 고르는 데 쓸모가 없다.
      // 색마다 한 줄씩 따라붙으면 판이 설명문처럼 보인다.
      await pumpThemeDialog(tester);

      expect(find.text('연핑크'), findsOneWidget);
      expect(find.textContaining('열려 있는 색'), findsNothing);

      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(1, 0))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('연 색이에요'), findsNothing);
    });

    testWidgets('적용하면 테마가 바뀌고 창이 닫힌다', (tester) async {
      final themeHandler = await pumpThemeDialog(tester);
      final target = ThemeLockManager.themeIndexAt(1, 0);

      await tester.tap(find.byKey(ThemeDialog.cellKey(target)));
      await tester.pumpAndSettle();
      await tapApply(tester);

      expect(themeHandler.primaryColor, ThemeLockManager.getThemeColor(target));
      expect(find.text('적용하기'), findsNothing);
      expect(find.text('창 열기'), findsOneWidget);
    });

    testWidgets('취소하면 색이 그대로고 창이 닫힌다', (tester) async {
      final themeHandler = await pumpThemeDialog(tester);

      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(1, 0))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(themeHandler.primaryColor, ThemeLockManager.getThemeColor(0));
      expect(find.text('취소'), findsNothing);
    });
  });

  group('트랙 여백', () {
    /// 색 트랙을 담고 있는 세로 스크롤. 24칸이 여기에 들어간다.
    ///
    /// 창 안에 다른 스크롤이 섞여 있어도 `ThemeDialog` 아래 것 중 세로로
    /// 움직이는 첫 번째가 트랙이다.
    ScrollPosition trackPosition(WidgetTester tester) {
      final states = tester.stateList<ScrollableState>(
        find.descendant(
          of: find.byType(ThemeDialog),
          matching: find.byType(Scrollable),
        ),
      );
      return states
          .firstWhere((state) => state.position.axis == Axis.vertical)
          .position;
    }

    for (final entry in <String, Size>{
      '390pt 폰': OnoSurface.phone,
      '태블릿': OnoSurface.tablet,
    }.entries) {
      testWidgets('${entry.key} 에서 24칸이 스크롤 없이 들어간다', (tester) async {
        // 트랙 끝 여백을 늘리면서 칸 사이를 그만큼 좁혔다. 한쪽만 건드리면
        // 여기서 걸린다. 스크롤이 생기면 색 스물넷을 한눈에 못 본다.
        await pumpThemeDialog(tester, surfaceSize: entry.value);

        expect(trackPosition(tester).maxScrollExtent, 0);
      });
    }

    testWidgets('잠긴 칸을 눌러 조건이 펼쳐져도 스크롤이 생기지 않는다', (tester) async {
      // 조건 한 줄이 붙으면서 위쪽 판이 그만큼 커진다. 그 바람에 격자가
      // 밀려 스크롤이 생기면, 조건을 보려고 누른 순간 색들이 움직인다.
      await pumpThemeDialog(tester, surfaceSize: OnoSurface.phone);

      await tester.tap(
        find.byKey(ThemeDialog.cellKey(ThemeLockManager.themeIndexAt(5, 3))),
      );
      await tester.pumpAndSettle();

      expect(trackPosition(tester).maxScrollExtent, 0);
    });

    testWidgets('첫 동그라미가 트랙 위 모서리에 붙지 않는다', (tester) async {
      await pumpThemeDialog(tester, surfaceSize: OnoSurface.phone);

      final first = tester.getRect(find.byKey(ThemeDialog.cellKey(0)));
      final second = tester.getRect(find.byKey(ThemeDialog.cellKey(4)));

      // 첫 칸이 가운데 칸보다 높다. 늘어난 자리가 바깥쪽에 붙어 있다는 뜻이다.
      expect(first.height, greaterThan(second.height));
    });
  });

  group('좁은 화면과 큰 글자', () {
    testWidgets('작은 폰에서도 넘치지 않는다', (tester) async {
      await pumpThemeDialog(tester, surfaceSize: OnoSurface.smallPhone);

      expect(tester.takeException(), isNull);
      expect(find.text('출석'), findsOneWidget);
    });

    testWidgets('태블릿에서도 넘치지 않는다', (tester) async {
      await pumpThemeDialog(tester, surfaceSize: OnoSurface.tablet);

      expect(tester.takeException(), isNull);
      expect(find.byKey(ThemeDialog.cellKey(23)), findsOneWidget);
    });

    testWidgets('작은 폰에서 글자를 키워도 넘치지 않는다', (tester) async {
      await pumpThemeDialog(
        tester,
        surfaceSize: OnoSurface.smallPhone,
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('작은 폰에서 글자 1.6배여도 넘치지 않고 조건이 그대로 읽힌다', (tester) async {
      await pumpThemeDialog(
        tester,
        surfaceSize: OnoSurface.smallPhone,
        textScale: 1.6,
      );

      expect(tester.takeException(), isNull);
      // 여백을 넓히면서 조건까지 밀려 사라지면 안 된다.
      expect(find.text('Lv.9'), findsNWidgets(1 + 4));
      expect(find.text('출석'), findsOneWidget);
    });

    testWidgets('글자를 아주 크게 키워도 버튼이 화면 밖으로 밀리지 않는다', (tester) async {
      await pumpThemeDialog(tester, textScale: 2.0);

      expect(tester.takeException(), isNull);
      for (final label in ['취소', '적용하기']) {
        final box = tester.getRect(find.text(label));
        expect(box.bottom, lessThanOrEqualTo(OnoSurface.phone.height));
        expect(box.top, greaterThanOrEqualTo(0));
      }
    });
  });
}
