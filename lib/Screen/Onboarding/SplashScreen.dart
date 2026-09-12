import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/HandwritingReveal.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Provider/UserProvider.dart';
import '../../Util/AppErrorReporter.dart';
import '../../Util/NotificationService.dart';
import '../../main.dart';
import 'LoginScreen.dart';
import 'OnboardingBrand.dart';

/// 앱을 켜면 제일 먼저 뜨는 화면이다.
///
/// 공책 줄 위에 개구리가 앉아 있고, 그 아래로 연필이 문구 한 줄을 적는다.
/// 그동안 뒤에서 자동 로그인을 하고, 글씨와 자동 로그인 중 늦은 쪽이 끝나면
/// 넘어간다.
///
/// 개구리는 앱 아이콘과 같은 그림이다. 사용자가 방금 누른 것이 그대로 나와야
/// 연 앱이 맞다는 것이 바로 읽힌다. 로그인 화면도 같은 그림을 쓰고 있어서
/// [Hero] 로 이어 붙였다.
///
/// 예전에는 자동 로그인이 끝난 **뒤에** 1.5초를 더 기다리고, 그러고 나서
/// 500ms 간격으로 상태를 다시 보는 방식이었다. 저장된 토큰으로 300ms 만에
/// 끝나도 화면은 늘 1.5초를 채웠다.
class SplashScreen extends StatefulWidget {
  /// 자동 로그인이 되어 있을 때 갈 화면.
  ///
  /// 홈은 탭 다섯을 `IndexedStack` 으로 한꺼번에 만들기 때문에, 위젯 테스트에서
  /// 그대로 띄우면 앱 화면 전체가 딸려 온다. 넘어가는 것 자체를 확인하려는
  /// 테스트가 홈의 모든 Provider 를 갖춰야 하는 셈이라, 가벼운 화면으로
  /// 바꿔 끼울 수 있게 열어 둔다.
  final WidgetBuilder? homeBuilder;

  const SplashScreen({super.key, this.homeBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 개구리가 앉는 높이. 화면 위에서부터의 비율이다.
  ///
  /// 둘 다 가운데 몰아 두었더니 위아래가 허전했다. 위아래로 벌려 화면을
  /// 나눠 쓰되, 너무 벌리면 둘이 따로 노는 그림이 되어 다시 조금 좁혔다.
  static const double _frogTop = 0.37;

  /// 글씨가 적히는 높이.
  static const double _textTop = 0.62;

  /// 개구리 크기.
  static const double _frogHeight = 140;

  /// 화면이 뜨고 나서 글씨를 쓰기 시작할 때까지 기다리는 시간.
  ///
  /// 뜨자마자 쓰기 시작하면 앱이 켜지는 순간과 겹쳐서 앞부분을 놓친다.
  static const Duration _writeDelay = Duration(milliseconds: 380);

  /// 밑줄까지 포함해 글씨를 다 쓰는 데 걸리는 시간.
  ///
  /// 처음에는 640ms 로 뒀는데 글씨 쓰는 구간이 460ms 밖에 안 되어서, 열일곱
  /// 자짜리 문구가 눈으로 따라갈 수 없는 속도로 지나갔다. 손으로 쓰는 속도에
  /// 맞춰 늘렸다.
  static const Duration _writeDuration = Duration(milliseconds: 1500);

  /// 자동 로그인을 기다리는 한계 시간.
  ///
  /// 서버 호출에 30초 타임아웃이 걸려 있어서 영영 멈추지는 않지만, 다 적힌
  /// 문구를 30초 동안 보고 있게 둘 수는 없다. 이 시간을 넘기면 로그인 화면으로
  /// 보낸다. 뒤늦게 로그인 상태가 되면 그 화면이 받아서 홈으로 넘긴다.
  static const Duration _autoLoginLimit = Duration(seconds: 8);

  /// 글씨를 다 쓰고 나서 화면에 머무는 시간.
  ///
  /// 마지막 획이 끝나자마자 넘어가면 방금 적은 것을 읽을 새가 없이 화면이
  /// 바뀌어서 쫓기는 느낌이 든다.
  static const Duration _afterWriteHold = Duration(milliseconds: 650);

  /// 글씨를 다 쓰고 [_afterWriteHold] 까지 지났을 때 완료된다. 움직임을 끈
  /// 기기에서는 첫 프레임 뒤에 바로 완료되므로 그런 기기는 자동 로그인이
  /// 끝나는 대로 넘어간다.
  final Completer<void> _writingDone = Completer<void>();

  Timer? _holdTimer;

  bool _navigated = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 자동 로그인과 연출을 같이 굴린다. 먼저 시작해 두고 연출을 기다리므로
    // 둘 중 늦은 쪽 시간만 쓴다.
    final loginCheck = _autoLogin(userProvider);
    await _writingDone.future;
    final loggedIn = await loginCheck;
    if (!mounted) return;

    _goNext(loggedIn);
  }

  /// 자동 로그인을 하고 로그인 상태인지 돌려준다. **어떤 경우에도 던지지
  /// 않는다.**
  ///
  /// [UserProvider.autoLogin] 은 저장된 토큰을 읽는 것을 try 블록 밖에서 한다.
  /// 안드로이드에서 보안 저장소가 손상되면([TokenProvider] 의 BAD_DECRYPT 처리)
  /// 거기서 예외가 올라오는데, 그 시점에는 로그인 상태가 아직 `waiting` 이라
  /// Provider 쪽 인증 실패 처리도 화면을 넘겨 주지 않는다. 여기서 막지 않으면
  /// 이 화면에서 나가지 못하고 갇힌다.
  Future<bool> _autoLogin(UserProvider userProvider) async {
    try {
      await userProvider.autoLogin().timeout(_autoLoginLimit);
      return userProvider.loginStatus == LoginStatus.login;
    } catch (error, stackTrace) {
      await AppErrorReporter.report(
        error,
        stackTrace,
        source: 'splash_auto_login',
        severity: AppErrorSeverity.warning,
      );
      // 로그인 화면으로 보낸다. 거기서 다시 로그인하면 되고, 뒤늦게 로그인
      // 상태가 되면 그 화면이 받아서 홈으로 넘긴다.
      return false;
    }
  }

  void _goNext(bool loggedIn) {
    if (_navigated) return;
    _navigated = true;

    if (!loggedIn) {
      // autoLogin 은 끝나면서 로그인이나 로그아웃 중 하나로 상태를 정한다.
      // 혹시 waiting 으로 남더라도 로그인 화면이 상태를 계속 보고 있어서,
      // 뒤늦게 로그인으로 바뀌면 그쪽에서 알아서 홈으로 넘어간다. 예전처럼
      // 여기서 500ms 간격으로 상태를 다시 볼 이유가 없다.
      Navigator.of(context).pushReplacement(
        TossPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      TossPageRoute(
        builder: widget.homeBuilder ?? (_) => const MyHomePage(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.processPendingNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingBrand.background,
      // 자리를 화면 높이의 비율로 잡는다. Alignment 로 두면 남는 공간을 기준
      // 으로 밀려서, 개구리처럼 큰 것은 지정한 비율에서 한참 벗어난다.
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            const Positioned.fill(child: _NotebookLines(gapTop: _textTop)),
            // 사용자가 방금 누른 앱 아이콘이 이 개구리다. 첫 화면에 그대로
            // 나와야 연 앱이 맞다는 것이 바로 읽힌다. 로그인 화면의 개구리와
            // 같은 그림이라 [Hero] 로 이어 붙여 두었다.
            _at(
              constraints.maxHeight * _frogTop,
              Hero(
                tag: OnboardingBrand.frogHeroTag,
                child: Image.asset(
                  OnboardingBrand.frogAsset,
                  height: _frogHeight,
                  fit: BoxFit.contain,
                  // 그림을 못 읽어도 첫 화면에 깨진 자리가 남으면 안 된다.
                  // 문구는 그대로 적히고 넘어가는 것도 그대로 된다.
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(height: _frogHeight),
                ),
              ),
            ),
            _at(
              constraints.maxHeight * _textTop,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FittedBox(
                  // 문구가 길어지거나 화면이 좁으면 줄바꿈 없이 줄어든다.
                  // 손글씨는 한 줄일 때만 왼쪽부터 적히는 것으로 보인다.
                  fit: BoxFit.scaleDown,
                  child: HandwritingReveal(
                    text: OnboardingBrand.phrase,
                    color: OnboardingBrand.ink,
                    fontSize: 30,
                    delay: _writeDelay,
                    duration: _writeDuration,
                    pencil: true,
                    underline: true,
                    underlineColor: OnboardingBrand.underline,
                    onCompleted: () {
                      // 움직임을 끈 기기에서는 글씨가 처음부터 완성돼 있으므로
                      // 읽으라고 잡아 둘 이유가 없다.
                      if (AppMotion.isReduced(context)) {
                        if (!_writingDone.isCompleted) _writingDone.complete();
                        return;
                      }
                      _holdTimer = Timer(_afterWriteHold, () {
                        if (!mounted) return;
                        if (!_writingDone.isCompleted) _writingDone.complete();
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [child] 의 한가운데가 화면 위에서 [y] 만큼 내려온 자리에 오게 놓는다.
  ///
  /// [FractionalTranslation] 은 자식 자신의 크기를 기준으로 밀기 때문에,
  /// 자식이 얼마나 큰지 몰라도 그 중심을 원하는 높이에 맞출 수 있다.
  Widget _at(double y, Widget child) {
    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: FractionalTranslation(
        translation: const Offset(0, -0.5),
        child: Center(child: child),
      ),
    );
  }
}

/// 뒤에 깔리는 공책 줄이다.
///
/// 흰 화면에 문구 한 줄만 두었더니 종이가 아니라 빈 화면처럼 보였다. 줄을
/// 깔면 공책에 적는 화면이 되고, 다음에 오는 로그인 화면의 공책 배경과도
/// 이어진다.
///
/// 글씨가 놓이는 자리는 비운다. 줄이 글자를 가로지르면 읽기 어렵고, 마침
/// 그 빈 자리가 지금 적고 있는 줄이 된다.
class _NotebookLines extends StatelessWidget {
  /// 줄을 비울 자리. 화면 위에서부터의 비율이다.
  final double gapTop;

  const _NotebookLines({required this.gapTop});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NotebookLinesPainter(
        color: OnboardingBrand.rule,
        gapTop: gapTop,
      ),
    );
  }
}

class _NotebookLinesPainter extends CustomPainter {
  final Color color;

  /// 화면 위에서부터의 비율이다.
  final double gapTop;

  _NotebookLinesPainter({required this.color, required this.gapTop});

  /// 줄 간격.
  static const double _spacing = 46;

  /// 글씨 자리를 비우는 높이. 위아래로 이만큼씩 줄을 걸러 낸다.
  static const double _gap = 52;

  /// 좌우로 들여 긋는 폭. 화면 끝까지 그으면 종이가 아니라 표처럼 보인다.
  static const double _margin = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // 글씨가 놓이는 높이에서 줄 간격을 맞춰 나간다. 그래야 비우는 자리가
    // 줄과 줄 사이에 정확히 들어간다.
    final center = size.height * gapTop;

    for (double y = center % _spacing; y <= size.height; y += _spacing) {
      if ((y - center).abs() < _gap) continue;
      canvas.drawLine(
        Offset(_margin, y),
        Offset(size.width - _margin, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter old) =>
      old.color != color || old.gapTop != gapTop;
}
