import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// iPadOS 26 에서 화면 왼쪽 위 (0, 0) 에 들어오는 가짜 터치를 버린다.
///
/// 버튼을 누르면 진짜 터치와 함께 (0, 0) 에 터치가 하나 더 들어와서, 방금 연
/// 다이얼로그나 바텀시트가 바깥을 눌린 줄 알고 바로 닫혔다. 화면 위쪽 버튼에서
/// 특히 잘 났고, 복습 세트 상세 앱바의 PDF 아이콘이 그랬다.
/// https://github.com/flutter/flutter/issues/177992
///
/// 그동안은 다이얼로그마다 배리어를 끄고 처음 0.5초 바깥 탭을 무시하는 우회를
/// 따로 넣어 왔는데, 빠진 곳마다 같은 증상이 다시 났다. 여기서 앱 전체에 한 번
/// 막는다. Flutter 3.41 에 들어간 고침은 크래시로 되돌려져서 아직 쓸 수 없다.
///
/// 사람이 정확히 (0, 0) 을 누를 일은 없어서 진짜 터치를 버릴 걱정은 없다.
class PhantomTapGuard {
  PhantomTapGuard._();

  static bool _installed = false;

  /// `WidgetsFlutterBinding.ensureInitialized()` 뒤에 한 번 부른다.
  static void install() {
    if (_installed || defaultTargetPlatform != TargetPlatform.iOS) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(absorb);
    _installed = true;
  }

  @visibleForTesting
  static void absorb(PointerEvent event) {
    if (event.position == Offset.zero) {
      GestureBinding.instance.cancelPointer(event.pointer);
    }
  }
}
