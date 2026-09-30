// 학습 달력 일기장 잉크 색 계산 테스트.
//
// 글씨를 검정과 회색 대신 테마 색에서 뽑은 잉크로 쓴다. 테마가 24가지라
// 어느 테마에서도 흰 종이 위에서 읽혀야 한다(대비 4.5:1). 위젯과 같은 식에서
// 출발해 색상(hue)은 그대로 두고 채도와 밝기만 내리는지 본다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeLockManager.dart';
import 'package:ono/Screen/User/Widget/DiaryTheme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('24개 테마 모두 흰 종이 위에서 읽히는 잉크가 나온다', () {
    for (var i = 0; i < ThemeLockManager.themeColors.length; i++) {
      final theme = ThemeLockManager.themeColors[i];
      final name = ThemeLockManager.themeNames[i];

      test('$name 테마', () {
        final ink = DiaryInk.of(theme);
        final themeHsl = HSLColor.fromColor(theme);
        final inkHsl = HSLColor.fromColor(ink.ink);
        final softHsl = HSLColor.fromColor(ink.soft);

        expect(_contrast(ink.ink, DiaryPaper.paper), greaterThanOrEqualTo(4.5));
        expect(
            _contrast(ink.soft, DiaryPaper.paper), greaterThanOrEqualTo(4.5));

        // 채도는 올리지 않고 상한만 둔다.
        expect(inkHsl.saturation,
            lessThanOrEqualTo(math.min(themeHsl.saturation, 0.5) + 0.02));
        expect(softHsl.saturation,
            lessThanOrEqualTo(math.min(themeHsl.saturation, 0.35) + 0.02));
        expect(inkHsl.lightness, lessThanOrEqualTo(0.305));
        expect(softHsl.lightness, lessThanOrEqualTo(0.455));
        // 보조는 본문보다 밝다.
        expect(softHsl.lightness, greaterThan(inkHsl.lightness));

        // 색이 있는 테마는 색상을 그대로 둔다.
        if (themeHsl.saturation > 0.05) {
          double hueGap(double a, double b) {
            final d = (a - b).abs() % 360;
            return math.min(d, 360 - d);
          }

          expect(hueGap(inkHsl.hue, themeHsl.hue), lessThan(2));
          expect(hueGap(softHsl.hue, themeHsl.hue), lessThan(2));
        }

        expect(ink.faint.a, closeTo(0.4, 0.01));

        // 형광펜 띠 위에서도 잉크가 읽힌다.
        expect(
          _contrast(Color.alphaBlend(ink.highlight, DiaryPaper.paper), ink.ink),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  test('연핑크 잉크는 밝기 0.30, 보조는 0.45 다', () {
    final ink = DiaryInk.of(Colors.pink[200]!);
    expect(HSLColor.fromColor(ink.ink).lightness, closeTo(0.30, 0.01));
    expect(HSLColor.fromColor(ink.soft).lightness, closeTo(0.45, 0.01));
    expect(HSLColor.fromColor(ink.ink).saturation, closeTo(0.5, 0.02));
  });

  test('밝게 보이는 초록 테마는 대비가 나올 때까지 보조 잉크를 더 내린다', () {
    final ink = DiaryInk.of(Colors.lightGreen);
    expect(HSLColor.fromColor(ink.soft).lightness, lessThan(0.45));
    expect(_contrast(ink.soft, DiaryPaper.paper), greaterThanOrEqualTo(4.5));
  });

  test('공부한 날 동그라미는 30%, 55%, 85% 로 칠하고 0 은 칠하지 않는다', () {
    final ink = DiaryInk.of(Colors.pink[200]!);
    expect(ink.levelFill(0).a, 0);
    expect(ink.levelFill(1).a, closeTo(0.30, 0.01));
    expect(ink.levelFill(2).a, closeTo(0.55, 0.01));
    expect(ink.levelFill(3).a, closeTo(0.85, 0.01));
  });

  test('진한 테마에서 진하게 칠한 칸만 흰 숫자로 바꾼다', () {
    final black = DiaryInk.of(Colors.black);
    expect(black.numberOn(3), Colors.white);
    expect(black.numberOn(0), black.ink);
    expect(black.numberOn(1), black.ink);

    final pink = DiaryInk.of(Colors.pink[200]!);
    for (final level in [0, 1, 2, 3]) {
      expect(pink.numberOn(level), pink.ink, reason: 'level $level');
    }
  });

  test('화면 바탕은 흰색에 테마 색을 아주 옅게 깐 색이다', () {
    final desk = DiaryPaper.deskOf(Colors.pink[200]!);
    expect(desk.computeLuminance(), greaterThan(0.9));
    expect(desk, isNot(Colors.white));
  });
}
