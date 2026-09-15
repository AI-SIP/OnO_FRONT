#!/bin/sh
# Debug 가 아닌 빌드에서 테스트 전용 플러그인 등록 코드를 뺀다.
#
# Flutter 는 iOS 에서 아직 dev_dependencies 플러그인을 Release 에서 걸러 주지 않는다
# (flutter/flutter#163874). 그래서 Podfile 에서 이 플러그인들의 pod 를 Debug 구성에만 링크하고,
# 여기서 Flutter 가 만든 GeneratedPluginRegistrant.m 의 import 와 등록 줄을 지운다. 둘 중 하나만
# 하면 Release 앱에 테스트 프레임워크가 들어가거나(pod 만 둘 때), 모듈을 못 찾아 빌드가 깨진다
# (등록 파일만 둘 때).
#
# Flutter 가 등록 파일 모양을 바꿔서 여기서 못 지우면 Release 빌드가 모듈을 못 찾아 실패한다.
# 조용히 테스트 프레임워크를 싣고 나가는 일은 없다.
set -eu

case "${CONFIGURATION}" in
  Debug*) exit 0 ;;
esac

# pubspec 의 dev_dependencies 중 iOS 네이티브 코드가 있는 것. Podfile 의 DEBUG_ONLY_PODS 와 맞춘다.
MODULES="integration_test patrol"
CLASSES="IntegrationTestPlugin PatrolPlugin"

REGISTRANT="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"
[ -f "${REGISTRANT}" ] || exit 0

TMP="${REGISTRANT}.strip"
awk -v modules="${MODULES}" -v classes="${CLASSES}" '
  BEGIN {
    n = split(modules, m, " "); for (i = 1; i <= n; i++) module[m[i]] = 1
    n = split(classes, c, " "); for (i = 1; i <= n; i++) class[c[i]] = 1
  }
  skipping { if ($0 ~ /^#endif/) skipping = 0; next }
  /^#if __has_include\(</ {
    name = $0
    sub(/^#if __has_include\(</, "", name)
    sub(/\/.*/, "", name)
    if (name in module) { skipping = 1; next }
  }
  /registerWithRegistrar:/ {
    for (k in class) if (index($0, "[" k " registerWithRegistrar:") > 0) next
  }
  { print }
' "${REGISTRANT}" > "${TMP}"

if ! cmp -s "${REGISTRANT}" "${TMP}"; then
  mv "${TMP}" "${REGISTRANT}"
  echo "note: 테스트 전용 플러그인(${CLASSES})을 ${CONFIGURATION} 등록 파일에서 뺐다"
else
  rm -f "${TMP}"
fi
