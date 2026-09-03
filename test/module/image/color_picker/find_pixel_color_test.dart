// FindPixelColor 테스트.
//
// 좌표 -> 색 추출 순수 로직. 실제 사용처는
// lib/Module/Image/ColorPicker/PixelPicker.dart:159 로, RepaintBoundary 를
// PNG 로 인코딩한 바이트를 그대로 넘긴다. 여기서도 `image` 패키지로 픽셀 색이
// 알려진 작은 PNG 를 직접 만들어 넘긴다.
//
// `image` 패키지의 내부 데이터는 #AABBGGRR 순서로 패킹되어 있다
// (image-3.3.0/lib/src/image.dart 의 `data` 필드 주석 참고). 이 좌표에 있는
// 픽셀 하나짜리 값을 그대로 넣어 `FindPixelColor.abgrToRgba` 가 Flutter 의
// `Color` 가 기대하는 #AARRGGBB 로 올바르게 변환하는지 본다.
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ono/Module/Image/ColorPicker/FindPixelColor.dart';

import '../../../helpers/helpers.dart';

/// [width] x [height] 크기에서, (a, r, g, b) 단색으로 채운 PNG 바이트를 만든다.
Uint8List _buildSolidPng({
  required int width,
  required int height,
  required int a,
  required int r,
  required int g,
  required int b,
}) {
  final image = img.Image(width, height);
  // image 패키지 내부 포맷은 #AABBGGRR 이다. Color(0xAARRGGBB) 와 헷갈리지
  // 않도록 여기서 직접 바이트 순서를 맞춰 패킹한다.
  final packed = (a << 24) | (b << 16) | (g << 8) | r;
  image.fill(packed);
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  setUpOnoTest();

  group('abgrToRgba (순수 변환)', () {
    test('완전 불투명 빨강을 ARGB 로 올바르게 변환한다', () {
      final picker = FindPixelColor();
      // image 패키지 포맷 #AABBGGRR: A=FF, B=00, G=00, R=FF.
      const abgrRed = 0xFF0000FF;

      final rgba = picker.abgrToRgba(abgrRed);

      expect(rgba, 0xFFFF0000); // Color 가 기대하는 #AARRGGBB 빨강.
    });

    test('완전 불투명 초록을 ARGB 로 올바르게 변환한다', () {
      final picker = FindPixelColor();
      // A=FF, B=00, G=FF, R=00.
      const abgrGreen = 0xFF00FF00;

      final rgba = picker.abgrToRgba(abgrGreen);

      expect(rgba, 0xFF00FF00);
    });

    test('완전 불투명 파랑을 ARGB 로 올바르게 변환한다', () {
      final picker = FindPixelColor();
      // A=FF, B=FF, G=00, R=00.
      const abgrBlue = 0xFFFF0000;

      final rgba = picker.abgrToRgba(abgrBlue);

      expect(rgba, 0xFF0000FF);
    });

    test('알파 채널을 그대로 보존한다', () {
      final picker = FindPixelColor();
      // A=80(반투명), B=00, G=00, R=00.
      const abgrHalfAlphaBlack = 0x80000000;

      final rgba = picker.abgrToRgba(abgrHalfAlphaBlack);

      expect((rgba >> 24) & 0xFF, 0x80);
    });

    test('완전 투명(0)은 검정 투명으로 변환된다', () {
      final picker = FindPixelColor();

      final rgba = picker.abgrToRgba(0);

      expect(rgba, 0);
    });

    test('완전 불투명 흰색을 올바르게 변환한다', () {
      final picker = FindPixelColor();
      const abgrWhite = 0xFFFFFFFF;

      final rgba = picker.abgrToRgba(abgrWhite);

      expect(rgba, 0xFFFFFFFF);
    });

    test('R/G/B 각 채널이 서로 다른 값일 때 자리바꿈 없이 변환된다', () {
      final picker = FindPixelColor();
      // A=FF, B=0x30, G=0x20, R=0x10 -> 기대: A=FF, R=0x10, G=0x20, B=0x30.
      const abgrMixed = 0xFF302010;

      final rgba = picker.abgrToRgba(abgrMixed);

      expect(rgba, 0xFF102030);
    });
  });

  group('getColor (실제 PNG 디코딩)', () {
    test('단색 이미지의 임의 좌표에서 그 색이 정확히 추출된다', () async {
      final bytes = _buildSolidPng(
        width: 10,
        height: 10,
        a: 255,
        r: 200,
        g: 100,
        b: 50,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(5, 5));

      expect(color, const Color.fromARGB(255, 200, 100, 50));
    });

    test('좌상단 경계 좌표 (0, 0) 에서 색을 추출할 수 있다', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(0, 0));

      expect(color, const Color.fromARGB(255, 10, 20, 30));
    });

    test('우하단 경계 좌표 (width - 1, height - 1) 에서 색을 추출할 수 있다', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(3, 3));

      expect(color, const Color.fromARGB(255, 10, 20, 30));
    });

    test('가로 범위를 벗어난 좌표(x == width)는 투명 검정을 반환한다', () async {
      // image 패키지의 getPixelSafe 는 boundsSafe 가 아니면 0 을 반환한다
      // (image-3.3.0/lib/src/image.dart:418, 427). 예외 없이 안전하게 처리된다.
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(4, 0));

      expect(color, const Color(0x00000000));
    });

    test('세로 범위를 벗어난 좌표(y == height)는 투명 검정을 반환한다', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(0, 4));

      expect(color, const Color(0x00000000));
    });

    test('음수 좌표는 예외 없이 투명 검정을 반환한다', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(-1, -1));

      expect(color, const Color(0x00000000));
    });

    test('이미지 크기보다 훨씬 큰 좌표도 예외 없이 투명 검정을 반환한다', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 10,
        g: 20,
        b: 30,
      );
      final picker = FindPixelColor(bytes: bytes);

      final color =
          await picker.getColor(pixelPosition: const Offset(9999, 9999));

      expect(color, const Color(0x00000000));
    });

    test('소수점 좌표는 반올림이 아니라 절삭(toInt)된다', () async {
      // (0,0) 은 r=10, (1,0) 은 r=90 인 2x1 이미지를 만들어, 1.9 가 반올림되면
      // 2(범위 밖 -> 투명)로, 절삭되면 1(r=90)로 나뉘는 지점을 확인한다.
      final image = img.Image(2, 1);
      image.setPixelRgba(0, 0, 10, 10, 10, 255);
      image.setPixelRgba(1, 0, 90, 90, 90, 255);
      final bytes = Uint8List.fromList(img.encodePng(image));
      final picker = FindPixelColor(bytes: bytes);

      final color = await picker.getColor(pixelPosition: const Offset(1.9, 0));

      expect(color, const Color.fromARGB(255, 90, 90, 90));
    });

    test('같은 인스턴스로 여러 번 호출해도 디코딩 결과가 일관된다(캐시)', () async {
      final bytes = _buildSolidPng(
        width: 4,
        height: 4,
        a: 255,
        r: 1,
        g: 2,
        b: 3,
      );
      final picker = FindPixelColor(bytes: bytes);

      final first = await picker.getColor(pixelPosition: const Offset(0, 0));
      final second = await picker.getColor(pixelPosition: const Offset(1, 1));

      expect(first, const Color.fromARGB(255, 1, 2, 3));
      expect(second, const Color.fromARGB(255, 1, 2, 3));
    });

    test('bytes 가 null 이면 예외를 던진다', () async {
      final picker = FindPixelColor();

      expect(
        () => picker.getColor(pixelPosition: const Offset(0, 0)),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
