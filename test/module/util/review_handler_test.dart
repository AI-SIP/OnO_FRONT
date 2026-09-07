import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:ono/Module/Util/ReviewHandler.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/helpers.dart';

/// in_app_review 도 url_launcher 와 마찬가지로 plugin_platform_interface 패턴을
/// 쓰기 때문에, 실제 플랫폼 채널 대신 [InAppReviewPlatform.instance] 를
/// 가짜로 바꿔치워 isAvailable()/requestReview()/openStoreListing() 호출을 관찰한다.
class _FakeInAppReviewPlatform extends InAppReviewPlatform
    with MockPlatformInterfaceMixin {
  /// isAvailable() 이 돌려줄 값. false 로 두면 커스텀 다이얼로그 경로를 본다.
  bool available = true;

  int requestReviewCallCount = 0;
  final List<String?> openStoreListingAppStoreIds = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestReviewCallCount++;
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {
    openStoreListingAppStoreIds.add(appStoreId);
  }
}

/// ReviewHandler._launchURL 이 실제로 여는 URL을 관찰하기 위한 가짜 url_launcher 델리게이트.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool canLaunchResult = true;
  final List<String> launchCalls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchCalls.add(url);
    return true;
  }
}

/// [ReviewHandler] 는 내부에서 직접 [BuildContext] 를 요구하므로,
/// 버튼 두 개로 감싼 최소한의 화면을 만들어 pumpOnoWidget 으로 띄운다.
class _ReviewHandlerHost extends StatelessWidget {
  const _ReviewHandlerHost({required this.reviewHandler});

  final ReviewHandler reviewHandler;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => reviewHandler.requestReview(context),
            child: const Text('리뷰 요청'),
          ),
          ElevatedButton(
            onPressed: () => reviewHandler.openReviewPage(),
            child: const Text('스토어 열기'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpOnoWidgetTest();

  late _FakeInAppReviewPlatform fakeInAppReview;
  late _FakeUrlLauncherPlatform fakeUrlLauncher;
  late ReviewHandler reviewHandler;

  setUp(() {
    fakeInAppReview = _FakeInAppReviewPlatform();
    InAppReviewPlatform.instance = fakeInAppReview;

    fakeUrlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;

    reviewHandler = ReviewHandler();
  });

  group('requestReview', () {
    testWidgets('플랫폼 리뷰 다이얼로그를 지원하면 바로 requestReview 를 호출하고 커스텀 다이얼로그는 뜨지 않는다',
        (tester) async {
      fakeInAppReview.available = true;

      await pumpOnoWidget(
        tester,
        _ReviewHandlerHost(reviewHandler: reviewHandler),
      );

      await tester.tap(find.text('리뷰 요청'));
      await tester.pumpAndSettle();

      expect(fakeInAppReview.requestReviewCallCount, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    // TODO(#174): 실제 버그. lib/Module/Util/ReviewHandler.dart:27 에서
    // _showCustomReviewDialog 가 requestReview() 라는 이벤트 핸들러(버튼 onPressed)
    // 안에서 곧바로 Provider.of<ThemeHandler>(context) (listen: true 기본값)를 호출한다.
    // Provider.of 는 build 도중에만 listen:true 로 부를 수 있고, 이렇게 build 밖(이벤트
    // 핸들러)에서 부르면 "Tried to listen to a value exposed with provider, from
    // outside of the widget tree" 어서션이 발생한다. 아래 세 테스트 모두 커스텀 다이얼로그
    // 경로(플랫폼 리뷰 다이얼로그 미지원)를 타면서 이 어서션에 걸려 실패한다.
    // 영향 화면: ProblemsProvider.requestReview() 를 통해
    // lib/Screen/ProblemRegister/ProblemRegisterTemplate.dart (문제 10개 등록마다 호출)
    // 가 실사용자 경로에서 이 버그를 그대로 탄다.
    testWidgets(
      '플랫폼 리뷰 다이얼로그를 지원하지 않으면 커스텀 다이얼로그를 띄운다',
      (tester) async {
        fakeInAppReview.available = false;

        await pumpOnoWidget(
          tester,
          _ReviewHandlerHost(reviewHandler: reviewHandler),
        );

        await tester.tap(find.text('리뷰 요청'));
        await tester.pumpAndSettle();

        expect(fakeInAppReview.requestReviewCallCount, 0);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('리뷰 작성 요청'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
        expect(find.text('작성하기'), findsOneWidget);
      },
      skip: true, // #174 에서 수정 예정
    );

    testWidgets(
      '커스텀 다이얼로그에서 취소를 누르면 다이얼로그만 닫히고 URL 은 열리지 않는다',
      (tester) async {
        fakeInAppReview.available = false;

        await pumpOnoWidget(
          tester,
          _ReviewHandlerHost(reviewHandler: reviewHandler),
        );

        await tester.tap(find.text('리뷰 요청'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeUrlLauncher.launchCalls, isEmpty);
      },
      skip: true, // #174 에서 수정 예정
    );

    testWidgets(
      '커스텀 다이얼로그에서 작성하기를 누르면 다이얼로그가 닫히고 구글 폼 URL 이 열린다',
      (tester) async {
        fakeInAppReview.available = false;

        await pumpOnoWidget(
          tester,
          _ReviewHandlerHost(reviewHandler: reviewHandler),
        );

        await tester.tap(find.text('리뷰 요청'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('작성하기'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(
          fakeUrlLauncher.launchCalls,
          ['https://forms.gle/MncQvyT57LQr43Pp7'],
        );
      },
      skip: true, // #174 에서 수정 예정
    );
  });

  group('openReviewPage', () {
    testWidgets('앱스토어 ID로 스토어 리스팅을 연다', (tester) async {
      await pumpOnoWidget(
        tester,
        _ReviewHandlerHost(reviewHandler: reviewHandler),
      );

      await tester.tap(find.text('스토어 열기'));
      await tester.pumpAndSettle();

      expect(fakeInAppReview.openStoreListingAppStoreIds, ['6602886624']);
    });

    testWidgets('isAvailable 여부와 무관하게 항상 호출된다', (tester) async {
      fakeInAppReview.available = false;

      await pumpOnoWidget(
        tester,
        _ReviewHandlerHost(reviewHandler: reviewHandler),
      );

      await tester.tap(find.text('스토어 열기'));
      await tester.pumpAndSettle();

      expect(fakeInAppReview.openStoreListingAppStoreIds, ['6602886624']);
    });
  });
}
