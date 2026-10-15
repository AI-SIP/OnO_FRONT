#!/usr/bin/env bash
# Edit/Write/MultiEdit 뒤에 실행되는 PostToolUse 훅.
# - 바꾼 파일이 .dart 가 아니면 아무것도 하지 않는다.
# - test/ 아래 파일만 dart format 을 적용한다. lib 는 기존 미포맷 파일이 많아서
#   CI 도 test 만 포맷 검사를 한다(.github/workflows/test.yml 포맷 검사 단계).
# - 그 파일 하나만 CI 와 같은 기준(info 는 무시, warning/error 는 실패)으로 analyze 하고,
#   warning/error 가 있으면 stderr 로 요약을 내고 exit 2 로 Claude 에게 알린다.
# - flutter/jq 가 없거나 판단할 수 없는 경우에는 작업을 막지 않도록 exit 0 으로 끝낸다.

set -u

command -v jq >/dev/null 2>&1 || exit 0
command -v flutter >/dev/null 2>&1 || exit 0

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ -n "$file" && "$file" == *.dart && -f "$file" ]] || exit 0

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$file" in
  "$project_dir"/*) rel="${file#"$project_dir"/}" ;;
  /*) exit 0 ;;  # 이 레포 밖 파일은 건드리지 않는다
  *) rel="$file" ;;
esac

cd "$project_dir" || exit 0

if [[ "$rel" == test/* ]]; then
  dart format "$rel" >/dev/null 2>&1 || true
fi

log=$(flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings "$rel" 2>&1)
problems=$(printf '%s\n' "$log" | grep -E '^[[:space:]]*(error|warning) •' || true)

if [[ -n "$problems" ]]; then
  count=$(printf '%s\n' "$problems" | wc -l | tr -d ' ')
  {
    echo "flutter analyze: $rel 에서 warning/error ${count}건 (CI 에서 실패하는 기준)"
    printf '%s\n' "$problems" | head -20
  } >&2
  exit 2
fi

exit 0
