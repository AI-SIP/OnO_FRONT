// `flutter test` 가 test/ 아래 모든 테스트 파일을 돌리기 전에 한 번씩 거치는 자리.
//
// 여기서는 골든 테스트(alchemist) 설정만 한다. 일반 위젯 테스트에는 영향이 없다.
import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  // GitHub Actions 는 CI=true 를 넣어 준다.
  final isRunningInCi = Platform.environment['CI'] == 'true';

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      // 화면 테스트는 화면 크기로 딱 맞춰 뜨므로 테두리나 여백이 필요 없다.
      goldenTestTheme: GoldenTestTheme(
        backgroundColor: Colors.white,
        borderColor: Colors.transparent,
        nameTextStyle: const TextStyle(fontSize: 12),
      ),
      // 진짜 폰트로 그리는 이미지. OS 마다 글자 렌더링이 달라서 커밋하지 않고
      // 로컬에서 눈으로 확인하는 데만 쓴다. CI 에서는 만들 필요가 없다.
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi),
      // 글자를 네모로 가린 이미지. OS 와 상관없이 거의 같게 나와서 이것만 커밋하고
      // CI 에서 비교한다.
      //
      // "거의"인 이유: 글자를 1.6배로 키우면 글자 폭이 소수점이 되고, 그 폭에 맞춰
      // 그려지는 진행 막대 끝이나 둥근 칩 테두리가 macOS 와 Linux 에서 1px 안쪽으로
      // 다르게 번진다. 실제로 재 보니 화면 한 장에 0.07%(223px)였다. 패딩 1px 이나
      // 색을 바꾸면 수천 px 이 달라지므로 0.2% 까지는 같은 이미지로 본다.
      ciGoldensConfig: const CiGoldensConfig(diffThreshold: 0.002),
    ),
    run: () async => testMain(),
  );
}
