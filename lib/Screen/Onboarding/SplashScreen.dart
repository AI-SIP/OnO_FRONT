import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/LoginStatus.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/HandwritingReveal.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Provider/UserProvider.dart';
import '../../Util/NotificationService.dart';
import '../../main.dart';
import 'LoginScreen.dart';
import 'OnboardingBrand.dart';

/// 앱을 켜면 제일 먼저 뜨는 화면이다.
///
/// 개구리가 위에서 떨어져 자리를 잡고 그 아래로 문구가 써진다. 그동안 뒤에서
/// 자동 로그인을 하고, 연출과 자동 로그인 중 늦은 쪽이 끝나면 넘어간다.
///
/// 예전에는 자동 로그인이 끝난 **뒤에** 1.5초를 더 기다리고, 그러고 나서
/// 500ms 간격으로 상태를 다시 보는 방식이었다. 저장된 토큰으로 300ms 만에
/// 끝나도 화면은 늘 1.5초를 채웠다.
class SplashScreen extends StatefulWidget {
  /// 자동 로그인이 되어 있을 때 갈 화면.
  ///
  /// 홈은 탭 넷을 `IndexedStack` 으로 한꺼번에 만들기 때문에, 위젯 테스트에서
  /// 그대로 띄우면 앱 화면 전체가 딸려 온다. 넘어가는 것 자체를 확인하려는
  /// 테스트가 홈의 모든 Provider 를 갖춰야 하는 셈이라, 가벼운 화면으로
  /// 바꿔 끼울 수 있게 열어 둔다.
  final WidgetBuilder? homeBuilder;

  const SplashScreen({super.key, this.homeBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 개구리가 떨어져 자리를 잡는 데 걸리는 시간.
  static const Duration _frogDrop = Duration(milliseconds: 380);

  /// 개구리가 자리를 잡을 때쯤부터 글씨를 쓰기 시작한다.
  static const Duration _writeDelay = Duration(milliseconds: 260);

  /// 밑줄까지 포함해 글씨를 다 쓰는 데 걸리는 시간.
  static const Duration _writeDuration = Duration(milliseconds: 640);

  /// 글씨를 다 썼을 때 완료된다. 움직임을 끈 기기에서는 첫 프레임 뒤에 바로
  /// 완료되므로 그런 기기는 자동 로그인이 끝나는 대로 넘어간다.
  final Completer<void> _writingDone = Completer<void>();

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 자동 로그인과 연출을 같이 굴린다. 연출이 끝나기를 기다리는 동안 로그인이
    // 진행되므로 둘 중 늦은 쪽 시간만 쓴다.
    await Future.wait<void>([
      userProvider.autoLogin(),
      _writingDone.future,
    ]);
    if (!mounted) return;

    _goNext(userProvider.loginStatus == LoginStatus.login);
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DroppingFrog(
              duration: _frogDrop,
              child: Hero(
                tag: OnboardingBrand.frogHeroTag,
                child: Image.asset(
                  OnboardingBrand.frogAsset,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            HandwritingReveal(
              text: OnboardingBrand.phrase,
              color: Colors.white,
              fontSize: 26,
              delay: _writeDelay,
              duration: _writeDuration,
              penTip: true,
              underline: true,
              onCompleted: () {
                if (!_writingDone.isCompleted) _writingDone.complete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 위에서 떨어져 자리를 잡는다.
///
/// 그냥 나타나기만 하면 아직 아무것도 시작하지 않은 정지 화면처럼 보인다.
/// 한 번 움직여 주면 앱이 켜지는 중이라는 것이 보인다.
class _DroppingFrog extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const _DroppingFrog({required this.child, required this.duration});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReduced(context)) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: AppMotion.emphasized,
      child: child,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -28 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
