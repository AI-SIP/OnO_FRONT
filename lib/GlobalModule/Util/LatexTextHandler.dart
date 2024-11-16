import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexTextHandler {
  /// 이 함수는 라텍스 컨텐츠를 적절하게 변환하고 폰트와 스타일을 적용하여 반환합니다.
  static TeXViewWidget renderLatex(String latexContent) {
    // 가독성 향상을 위해 변환 작업 수행
    String convertedContent = _convertToReadableLatex(latexContent);

    String latexWithLineSpacing = '''
      <html>
        <head>
          <style>
            body { line-height: 1.8; font-family: 'PrentendardThin'; font-size: 10pt; }
          </style>
        </head>
        <body>
          $convertedContent
        </body>
      </html>
    ''';

    return TeXViewDocument(
      latexWithLineSpacing,
      style: TeXViewStyle(
        margin: const TeXViewMargin.all(10),
        padding: const TeXViewPadding.all(10),
        borderRadius: const TeXViewBorderRadius.all(10),
        backgroundColor: Colors.white,
        fontStyle: TeXViewFontStyle(
          fontFamily: 'PrentendardThin', // Custom Font 적용
          fontSize: 10,
          sizeUnit: TeXViewSizeUnit.pt,
        ),
      ),
    );
  }

  /// 가독성을 향상시키기 위한 전체 변환 함수
  static String _convertToReadableLatex(String content) {
    // 1. 헤더(#) 변환
    String convertedContent = _convertHeaders(content);

    // 2. \n을 <br>로 변환
    convertedContent = _convertLineBreaks(convertedContent);

    // 3. ** **로 감싸진 텍스트를 굵게 변환
    convertedContent = _convertBoldText(convertedContent);

    // 4. 마침표 뒤 줄바꿈 적용
    convertedContent = _applyLineBreaks(convertedContent);

    return convertedContent;
  }

  /// #이 2개 이상 붙은 텍스트를 굵게하고 크기를 키우는 함수
  static String _convertHeaders(String content) {
    // 정규식을 사용하여 ##으로 시작하는 텍스트를 <h1> 태그로 변환
    return content.replaceAllMapped(RegExp(r'###\s*(.*?)\n'), (match) {
      return "<h4>${match.group(1)}</h4>";
    });
  }

  /// \n을 <br>로 변환하는 함수
  static String _convertLineBreaks(String content) {
    return content.replaceAll('\n', '<br>'); // \n을 <br>로 변환
  }

  /// ** **로 감싸진 텍스트를 굵게 변환하는 함수
  static String _convertBoldText(String content) {
    // 정규식을 사용하여 **로 감싸진 텍스트를 <b>태그로 감싸진 형태로 변환하고 줄바꿈 추가
    return content.replaceAllMapped(RegExp(r'\*\*\s*(.*?)\s*\*\*'), (match) {
      return "<b>${match.group(1)}</b><br><br>";
    });
  }

  /// 긴 텍스트에 대해 적절한 줄바꿈과 간격을 추가하는 함수
  static String _applyLineBreaks(String content) {
    // 숫자 뒤에 오는 마침표는 줄넘김을 하지 않음
    // 숫자가 아닌 문자 뒤에 마침표가 오면 줄바꿈 추가
    return content.replaceAllMapped(RegExp(r'(?<!\d)\.(\s)'), (match) {
      // 숫자가 아닌 문자 뒤의 마침표와 공백을 감지
      return ".<br><br>${match.group(1)}"; // <br><br> 추가
    });
  }
}