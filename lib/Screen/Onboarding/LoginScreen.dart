import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/UserProvider.dart';
import '../../main.dart';
import 'OnboardingBrand.dart';

/// 로그인 화면이다.
///
/// 개구리와 문구, 로그인 수단이 차례로 올라온다.
class LoginScreen extends StatefulWidget {
  /// 로그인이 끝나면 갈 화면.
  ///
  /// 홈은 탭 다섯을 `IndexedStack` 으로 한꺼번에 만들기 때문에, 위젯 테스트에서
  /// 그대로 띄우면 앱 화면 전체가 딸려 온다. 넘어가는 것 자체를 확인하려는
  /// 테스트가 홈의 모든 Provider 를 갖춰야 하는 셈이라, 가벼운 화면으로
  /// 바꿔 끼울 수 있게 열어 둔다.
  final WidgetBuilder? homeBuilder;

  const LoginScreen({super.key, this.homeBuilder});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// 로그인 버튼 묶음의 최대 폭.
  ///
  /// 예전에는 화면 폭의 80% 였는데, 태블릿에서는 버튼 하나가 화면을 가로질러
  /// 길게 늘어났다. 버튼 그림 자체가 343x54 라 그보다 크게 늘리면 비율만
  /// 커지고 눌러야 할 곳이 어디인지 흐려진다.
  static const double _maxContentWidth = 400;

  /// 소셜 로그인 버튼 그림의 가로 세로 비율(343x54).
  ///
  /// 예전에는 높이를 화면 높이의 6.5% 로 따로 잡아서 그림이 상자 안에서
  /// 위아래로 남는 자리를 두고 그려졌다. 누를 수 있는 영역과 눈에 보이는
  /// 버튼이 어긋나 있었다.
  static const double _buttonAspectRatio = 343 / 54;

  /// 스플래시에서 개구리가 날아오는 동안에는 버튼을 세워 두고, 개구리가
  /// 자리를 잡은 뒤에 올라오게 한다.
  static const Duration _buttonsDelay = AppMotion.page;

  /// 로그인이 끝나 홈으로 넘긴 뒤인지.
  ///
  /// 예전에는 이 값이 `build` 안의 지역 변수였다. 로그인이 끝나면
  /// [UserProvider] 가 알림을 보내고 [Consumer] 가 다시 build 되는데, 그때마다
  /// 값이 false 로 되돌아가서 화면을 넘기는 예약이 여러 번 걸릴 수 있었다.
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                gridColor: themeProvider.primaryColor,
                isSpring: true,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 작은 폰에서는 개구리와 버튼 넷이 세로로 다 안 들어간다.
                // 그때는 넘치는 대신 스크롤되게 둔다.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _frog(
                                context,
                                themeProvider.primaryColor,
                                constraints.maxHeight,
                              ),
                            ),
                            _loginActions(),
                            const SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 개구리와 그 아래 문구다.
  ///
  /// 문구는 스플래시에서 이미 써 보여줬으므로 여기서는 다시 쓰지 않고 떠오르기만
  /// 한다.
  /// [available] 은 이 화면이 쓸 수 있는 세로 길이다.
  ///
  /// 전에는 짧은 쪽이 600 이상이면 태블릿으로 치고 개구리를 180, 그 아래 간격을
  /// 56 으로 못 박았다. 아이패드 mini 를 가로로 두면 짧은 쪽이 744 라 태블릿으로
  /// 걸리는데 세로로 쓸 수 있는 길이는 700 밖에 안 돼서, 맨 아래 게스트로
  /// 시작하기가 40 만큼 밀려 스크롤해야 보였다. 글자 크기를 키운 기기에서는
  /// 61 까지 밀렸다.
  ///
  /// 그래서 기기 종류가 아니라 실제로 남은 세로 길이를 보고 정한다. 여유가 있는
  /// 세로 화면에서는 위아래 한계에 걸려 지금과 같은 크기가 나온다.
  Widget _frog(BuildContext context, Color color, double available) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final frogHeight = (available * 0.17).clamp(100.0, 190.0);
    final frogGap = (available * 0.05).clamp(24.0, 56.0);

    return Align(
      // 가운데에 두면 위쪽 여백이 허전하고 버튼 묶음과도 붙어 보인다. 조금
      // 내려서 화면 위아래 무게를 맞춘다.
      alignment: const Alignment(0, 0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 스플래시에서 날아온다. 여기서 따로 나타나는 연출을 붙이지 않는다.
          // [Hero] 가 자리를 잡는 것이 이미 등장 연출이라, 위에 하나를 더
          // 얹으면 두 번 움직인다.
          Hero(
            tag: OnboardingBrand.frogHeroTag,
            child: Image.asset(
              OnboardingBrand.frogAsset,
              height: frogHeight,
              fit: BoxFit.contain,
              // 그림을 못 읽어도 로그인 버튼까지 못 쓰게 되면 안 된다.
              errorBuilder: (_, __, ___) => SizedBox(height: frogHeight),
            ),
          ),
          SizedBox(height: frogGap),
          AppearTransition(
            delay: _buttonsDelay,
            child: HandWriteText(
              text: OnboardingBrand.phrase,
              fontSize: isTablet ? 34 : 28,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginActions() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        _navigateToHomeIfLoggedIn(userProvider);

        final buttons = <Widget>[
          _socialButton(
            onPressed: () => userProvider.signInWithGoogle(context),
            assetPath: 'assets/SocialLogin/GoogleLogin.svg',
            label: '구글로 로그인',
          ),
          // dart:io 의 Platform 이 아니라 테마의 플랫폼으로 판단한다. 앱 테마는
          // 플랫폼을 따로 정하지 않아서 기기에서는 결과가 같고, 테스트에서는 테마로
          // 플랫폼을 흉내 낼 수 있다. Platform 으로 두면 macOS 개발기에서는 버튼이
          // 있고 Linux CI 에서는 없어서 골든 이미지가 둘로 갈렸다.
          if (Theme.of(context).platform == TargetPlatform.iOS ||
              Theme.of(context).platform == TargetPlatform.macOS)
            _socialButton(
              onPressed: () => userProvider.signInWithApple(context),
              assetPath: 'assets/SocialLogin/AppleLogin.svg',
              label: '애플로 로그인',
            ),
          _socialButton(
            onPressed: () => userProvider.signInWithKakao(context),
            assetPath: 'assets/SocialLogin/KakaoLogin.svg',
            label: '카카오로 로그인',
          ),
          _guestButton(),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppearTransition.stagger(
                buttons,
                initialDelay: _buttonsDelay,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 로그인이 끝났으면 홈으로 넘긴다.
  ///
  /// 스플래시가 로그인 상태를 정하지 못한 채로 이 화면을 띄운 경우에도, 뒤늦게
  /// 상태가 로그인으로 바뀌면 여기서 받아 넘어간다.
  void _navigateToHomeIfLoggedIn(UserProvider userProvider) {
    if (_navigated) return;
    if (userProvider.loginStatus != LoginStatus.login) return;

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        TossPageRoute(
          builder: widget.homeBuilder ?? (_) => const MyHomePage(),
        ),
      );
    });
  }

  /// 소셜 로그인 버튼이다.
  ///
  /// 그림은 브랜드에서 정한 모양 그대로 쓴다. 직접 그리면 애플과 구글의 버튼
  /// 규정에 걸려 심사에서 막힐 수 있다. 대신 [PressableScale] 로 감싸는 것은
  /// 그림에 손대는 것이 아니므로 눌림과 진동은 넣는다.
  Widget _socialButton({
    required VoidCallback onPressed,
    required String assetPath,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PressableScale(
        onTap: onPressed,
        child: Semantics(
          button: true,
          label: label,
          child: AspectRatio(
            aspectRatio: _buttonAspectRatio,
            child: SvgPicture.asset(assetPath, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }

  /// 게스트로 시작하는 버튼이다.
  ///
  /// 일부러 눈에 안 띄게 둔다. 게스트로 시작하면 기기를 바꿀 때 오답노트를
  /// 가져갈 수 없고 로그아웃하면 그동안 쌓은 것이 사라진다. 소셜 로그인과
  /// 나란히 놓고 똑같이 강조하면 그 차이를 모른 채로 고르게 된다.
  ///
  /// 대신 누르는 영역은 글자보다 넓게 잡아 둔다. 눈에 덜 띄는 것과 누르기
  /// 어려운 것은 다르다.
  Widget _guestButton() {
    return PressableScale(
      onTap: () => _showGuestLoginDialog(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        alignment: Alignment.center,
        child: const StandardText(
          text: '게스트로 시작하기',
          fontSize: 13,
          color: AppColors.textDisabled,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showGuestLoginDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showTossDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withValues(alpha: 0.14),
                      themeProvider.primaryColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: StandardText(
                        text: '게스트 로그인 안내',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StandardText(
                        text: '• 기기 간 오답노트 연동이 불가능해요.',
                        fontSize: 14,
                        color: Colors.grey[800]!,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StandardText(
                        text: '• 로그아웃 시 모든 정보가 삭제돼요.',
                        fontSize: 14,
                        color: Colors.grey[800]!,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Provider.of<UserProvider>(context, listen: false)
                              .signInWithGuest(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                          ),
                        ),
                        child: const StandardText(
                          text: '확인',
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
