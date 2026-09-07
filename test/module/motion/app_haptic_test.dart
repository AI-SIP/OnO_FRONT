// AppHaptic 테스트.
//
// 진동 자체는 테스트에서 확인할 수 없으니, 어떤 종류를 플랫폼에 요청했는지를
// 채널 호출로 본다. 세기를 잘못 매핑하면 되돌리기 어려운 액션에 약한 진동이
// 가거나 그 반대가 되는데, 손에 기기를 들기 전에는 알아채기 어렵다.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AppHaptic.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  late List<String> requested;

  setUp(() {
    requested = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        requested.add(call.arguments as String? ?? 'default');
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('primary 는 중간 세기를 요청한다', () async {
    await AppHaptic.primary();
    expect(requested, ['HapticFeedbackType.mediumImpact']);
  });

  test('secondary 는 약한 세기를 요청한다', () async {
    await AppHaptic.secondary();
    expect(requested, ['HapticFeedbackType.lightImpact']);
  });

  test('selection 은 선택 변경을 요청한다', () async {
    await AppHaptic.selection();
    expect(requested, ['HapticFeedbackType.selectionClick']);
  });

  test('of(none) 은 아무것도 요청하지 않는다', () async {
    await AppHaptic.of(HapticLevel.none);
    expect(requested, isEmpty);
  });

  test('of 는 각 단계를 해당 세기로 넘긴다', () async {
    await AppHaptic.of(HapticLevel.primary);
    await AppHaptic.of(HapticLevel.secondary);
    await AppHaptic.of(HapticLevel.selection);

    expect(requested, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
    ]);
  });
}
