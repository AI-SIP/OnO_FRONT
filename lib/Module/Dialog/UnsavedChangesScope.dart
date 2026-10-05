import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Util/AppAnalytics.dart';
import 'ConfirmDialog.dart';

/// 쓰던 내용이 있으면 뒤로 가기 전에 정말 나갈지 묻는다.
///
/// 앱바 뒤로가기, 안드로이드 뒤로가기, iOS 밀어서 뒤로가기를 모두 막는다.
/// 쓴 것이 없으면 그냥 나간다. 저장이 끝나 화면이 스스로 닫을 때 쓰는
/// `Navigator.pop` 은 막지 않는다.
///
/// 쓴 것이 있는지 화면이 다시 그려질 때마다 알 수 있으면 [hasChanges] 를
/// 넘긴다. 그러면 쓴 것이 없을 때는 iOS 밀어서 뒤로가기가 그대로 살아 있다.
/// 필기처럼 화면을 다시 그리지 않고 바뀌는 것은 [checkChanges] 를 넘긴다.
/// 이때는 늘 막아 두고, 나가려는 순간에 확인한다.
class UnsavedChangesScope extends StatefulWidget {
  final ValueListenable<bool>? hasChanges;
  final bool Function()? checkChanges;
  final Widget child;

  /// 애널리틱스에 남길 화면 이름.
  final String source;
  final String title;
  final String description;

  const UnsavedChangesScope({
    super.key,
    required ValueListenable<bool> this.hasChanges,
    required this.child,
    required this.source,
    this.title = '작성을 그만둘까요?',
    this.description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  }) : checkChanges = null;

  const UnsavedChangesScope.check({
    super.key,
    required bool Function() this.checkChanges,
    required this.child,
    required this.source,
    this.title = '작성을 그만둘까요?',
    this.description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  }) : hasChanges = null;

  /// 지금 화면에 떠 있는 것들. 알림이나 홈 위젯처럼 화면을 한꺼번에 닫고
  /// 이동하는 길은 PopScope 를 거치지 않아서, 여기서 직접 물어본다.
  /// 이 위젯으로 감싸지 않고 PopScope 를 직접 쓰는 화면은 [register] 로
  /// 여기에 들어온다.
  static final Map<State, bool Function()> _mounted = {};

  /// 이 위젯으로 감쌀 수 없는 화면을 확인 목록에 넣는다. 여러 장 등록이나
  /// 카메라처럼 뒤로 가기가 단계를 되돌리는 화면이 쓴다. initState 에서 넣고
  /// dispose 에서 [unregister] 로 뺀다.
  static void register(State state, bool Function() hasChanges) {
    _mounted[state] = hasChanges;
  }

  static void unregister(State state) {
    _mounted.remove(state);
  }

  /// 쓰던 내용이 있는 화면이 하나라도 있으면 그걸 두고 이동할지 묻는다.
  /// 이동해도 되면 true 다.
  ///
  /// `popUntil` 로 쌓인 화면을 한꺼번에 닫기 전에 부른다.
  static Future<bool> confirmBeforeLeavingAll({required String source}) async {
    final changed = _mounted.entries
        .where((entry) => entry.key.mounted && entry.value())
        .map((entry) => entry.key);
    if (changed.isEmpty) return true;
    // 쓰던 화면 위에서 묻는다. 그 화면이 가장 위에 있으니 확인 창도 그 위에 뜬다.
    return confirmLeave(
      changed.last.context,
      source: source,
      title: '쓰던 내용을 두고 이동할까요?',
      description: '지금 이동하면 쓰던 내용이 저장되지 않아요.',
      leaveLabel: '이동하기',
    );
  }

  @override
  State<UnsavedChangesScope> createState() => _UnsavedChangesScopeState();
}

class _UnsavedChangesScopeState extends State<UnsavedChangesScope> {
  bool get _hasChanges =>
      widget.hasChanges?.value ?? widget.checkChanges?.call() ?? false;

  @override
  void initState() {
    super.initState();
    UnsavedChangesScope.register(this, () => _hasChanges);
  }

  @override
  void dispose() {
    UnsavedChangesScope.unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = widget.hasChanges;
    if (hasChanges == null) {
      return _buildScope(context, canPop: false);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: hasChanges,
      builder: (context, changed, _) => _buildScope(context, canPop: !changed),
    );
  }

  Widget _buildScope(BuildContext context, {required bool canPop}) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_hasChanges) {
          Navigator.of(context).pop();
          return;
        }
        final leave = await confirmLeave(
          context,
          source: widget.source,
          title: widget.title,
          description: widget.description,
        );
        if (leave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}

/// 쓰던 내용을 버리고 나갈지 묻는다. 나가기를 고르면 true 다.
///
/// 뒤로 가기가 아니라 단계를 되돌리는 곳처럼 [UnsavedChangesScope] 로 감쌀 수
/// 없는 자리에서 직접 부른다.
Future<bool> confirmLeave(
  BuildContext context, {
  required String source,
  String title = '작성을 그만둘까요?',
  String description = '지금 나가면 쓰던 내용이 저장되지 않아요.',
  String stayLabel = '계속 쓰기',
  String leaveLabel = '나가기',
}) async {
  final leave = await showConfirmDialog(
    context,
    title: title,
    message: description,
    confirmLabel: leaveLabel,
    cancelLabel: stayLabel,
    destructive: true,
    icon: Icons.edit_off_outlined,
  );
  AppAnalytics.logEvent('leave_confirm', {
    'source': source,
    'result': leave ? 'leave' : 'stay',
  });
  return leave;
}
