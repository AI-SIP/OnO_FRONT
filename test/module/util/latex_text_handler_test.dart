import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:ono/Module/Util/LatexTextHandler.dart';

import '../../helpers/helpers.dart';

/// [LatexTextHandler] 의 변환 로직은 전부 private static 함수라 직접 호출할 수 없다.
/// 대신 공개 API인 [LatexTextHandler.renderLatex] 의 반환값인
/// [TeXViewDocument.data] (변환된 HTML 문자열)를 통해 간접적으로 검증한다.
String _renderedData(String input) {
  final widget = LatexTextHandler.renderLatex(input);
  expect(widget, isA<TeXViewDocument>());
  return (widget as TeXViewDocument).data;
}

void main() {
  setUpOnoTest();

  group('수식/특수 문법이 없는 평문', () {
    test('내용이 그대로 body 안에 들어간다', () {
      final data = _renderedData('안녕하세요');

      expect(data, contains('<html>'));
      expect(data, contains('<body>'));
      expect(data, contains('안녕하세요'));
    });

    test('빈 문자열을 넣어도 예외 없이 빈 본문을 만든다', () {
      expect(() => _renderedData(''), returnsNormally);

      final data = _renderedData('');
      expect(data, contains('<body>'));
      expect(data, contains('</body>'));
    });
  });

  group('# 헤더 변환', () {
    test('###으로 시작하고 줄바꿈으로 끝나면 <h4> 로 변환되고 줄바꿈은 사라진다', () {
      final data = _renderedData('### 제목\n본문');

      // 헤더 변환이 먼저 일어나며, ### 부터 \n 까지를 통째로 소비하기 때문에
      // 변환된 헤더와 다음 내용 사이에는 <br> 이 남지 않는다.
      expect(data, contains('<h4>제목</h4>본문'));
      expect(data, isNot(contains('###')));
    });

    test('###으로 시작해도 뒤에 줄바꿈이 없으면(마지막 줄) 변환되지 않는다', () {
      // 헤더 정규식 `###\s*(.*?)\n` 은 반드시 뒤따르는 \n 이 있어야 매치된다.
      // 문자열의 마지막 줄이라 \n 이 없는 경우, 헤더로 인식되지 않고 원문 그대로 남는다.
      final data = _renderedData('### 마지막 줄 제목');

      expect(data, contains('### 마지막 줄 제목'));
      expect(data, isNot(contains('<h4>')));
    });
  });

  group('줄바꿈(\\n) 변환', () {
    test('\\n 은 <br> 로 바뀐다', () {
      final data = _renderedData('첫줄\n둘째줄\n셋째줄');

      expect(data, contains('첫줄<br>둘째줄<br>셋째줄'));
    });
  });

  group('** ** 굵게 변환', () {
    test('짝이 맞는 ** ** 는 <b> 태그로 바뀌고 뒤에 줄바꿈이 붙는다', () {
      final data = _renderedData('**굵게**입니다');

      expect(data, contains('<b>굵게</b><br>입니다'));
    });

    test('여러 개의 굵게 구간을 각각 변환한다', () {
      final data = _renderedData('**A** 그리고 **B**');

      expect(data, contains('<b>A</b><br>'));
      expect(data, contains('<b>B</b><br>'));
    });

    test('별표가 하나뿐인 경우(잘못된 델리미터)는 변환되지 않는다', () {
      final data = _renderedData('이것은 *굵게* 아닙니다');

      expect(data, isNot(contains('<b>')));
      expect(data, contains('*굵게*'));
    });

    test('여는 ** 만 있고 닫는 ** 가 없으면 변환되지 않는다', () {
      final data = _renderedData('**닫히지 않은 굵게 표시');

      expect(data, isNot(contains('<b>')));
      expect(data, contains('**닫히지 않은 굵게 표시'));
    });
  });

  group('마침표 뒤 줄바꿈', () {
    test('숫자가 아닌 문자 뒤 마침표+공백은 <br><br> 으로 바뀐다', () {
      final data = _renderedData('문장입니다. 다음 문장');

      expect(data, contains('문장입니다.<br><br> 다음 문장'));
    });

    test('문자열 끝의 마침표(뒤에 공백 없음)는 변환되지 않는다', () {
      final data = _renderedData('마지막 문장입니다.');

      expect(data, isNot(contains('<br><br>')));
      expect(data, contains('마지막 문장입니다.'));
    });

    test('숫자 바로 뒤의 마침표(번호 매기기 등)는 줄바꿈되지 않는다', () {
      final data = _renderedData('1. 첫 번째 항목');

      expect(data, isNot(contains('<br><br>')));
      expect(data, contains('1. 첫 번째 항목'));
    });
  });

  group('혼합 케이스', () {
    test('헤더 + 굵게 + 마침표 줄바꿈이 함께 있어도 각자 규칙대로 변환된다', () {
      final data = _renderedData('### 제목\n**핵심**입니다. 확인하세요.');

      expect(data, contains('<h4>제목</h4>'));
      expect(data, contains('<b>핵심</b><br>'));
      expect(data, contains('입니다.<br><br> 확인하세요.'));
    });
  });

  group('renderLatex 반환값(TeXViewDocument) 스타일', () {
    test('스타일 값이 지정한 대로 채워진다', () {
      final widget = LatexTextHandler.renderLatex('내용') as TeXViewDocument;

      expect(widget.style, isNotNull);
      final style = widget.style!;
      expect(style.backgroundColor, Colors.white);
      expect(style.fontStyle?.fontFamily, 'PrentendardThin');
      expect(style.fontStyle?.fontSize, 10);
      expect(style.fontStyle?.sizeUnit, TeXViewSizeUnit.pt);
    });
  });
}
