// PickerResponse 테스트.
//
// 검증/변환 로직이 전혀 없는 순수 데이터 홀더다. 생성자 위치 인자 순서대로
// 필드에 그대로 대입되는지만 확인한다. 실제 생성 지점은
// lib/Module/Image/ColorPicker/PixelPicker.dart:167 의 `_onInteract` 이며,
// 인자 순서는 (selectionColor, redScale, blueScale, greenScale, hexCode,
// xpostion, ypostion) 이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Image/ColorPicker/PickerResponse.dart';

import '../../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('필드 대입', () {
    test('생성자 위치 인자가 순서대로 각 필드에 들어간다', () {
      final response = PickerResponse(
        const Color(0xFFFF0000),
        255,
        0,
        0,
        '#ff0000',
        12.5,
        34.5,
      );

      expect(response.selectionColor, const Color(0xFFFF0000));
      expect(response.redScale, 255);
      expect(response.blueScale, 0);
      expect(response.greenScale, 0);
      expect(response.hexCode, '#ff0000');
      expect(response.xpostion, 12.5);
      expect(response.ypostion, 34.5);
    });

    test('red/blue/green 인자 순서가 뒤섞이지 않고 각자의 필드에 들어간다', () {
      // redScale, blueScale, greenScale 을 서로 다른 값으로 넣어 자리바꿈 여부를 본다.
      final response = PickerResponse(
        const Color(0xFF102030),
        10,
        20,
        30,
        '#0a1420',
        0,
        0,
      );

      expect(response.redScale, 10);
      expect(response.blueScale, 20);
      expect(response.greenScale, 30);
    });
  });

  group('경계값', () {
    test('색상 채널 값 0 을 그대로 보존한다', () {
      final response = PickerResponse(
        Colors.black,
        0,
        0,
        0,
        '#000000',
        0,
        0,
      );

      expect(response.redScale, 0);
      expect(response.blueScale, 0);
      expect(response.greenScale, 0);
    });

    test('색상 채널 값 255 를 그대로 보존한다', () {
      final response = PickerResponse(
        Colors.white,
        255,
        255,
        255,
        '#ffffff',
        0,
        0,
      );

      expect(response.redScale, 255);
      expect(response.blueScale, 255);
      expect(response.greenScale, 255);
    });

    test('좌표에 음수 값이 들어와도 그대로 보존한다', () {
      final response = PickerResponse(
        Colors.grey,
        1,
        2,
        3,
        '#010203',
        -10.0,
        -20.0,
      );

      expect(response.xpostion, -10.0);
      expect(response.ypostion, -20.0);
    });

    test('좌표에 0.0 이 들어와도 그대로 보존한다', () {
      final response = PickerResponse(
        Colors.grey,
        1,
        2,
        3,
        '#010203',
        0.0,
        0.0,
      );

      expect(response.xpostion, 0.0);
      expect(response.ypostion, 0.0);
    });

    test('hexCode 는 검증 없이 입력 문자열 그대로 저장된다', () {
      // 이 클래스는 형식을 검증하지 않는다. 빈 문자열이나 '#' 없는 문자열도 그대로 통과한다.
      final response = PickerResponse(
        Colors.grey,
        0,
        0,
        0,
        'not-a-hex-code',
        0,
        0,
      );

      expect(response.hexCode, 'not-a-hex-code');
    });
  });
}
