import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexTextHandler {
  /// 이 함수는 라텍스 컨텐츠를 적절하게 변환하고 폰트와 스타일을 적용하여 반환합니다.
  static TeXViewWidget renderLatex(String latexContent) {
    // 가독성 향상을 위해 변환 작업 수행
    String convertedContent = _convertToReadableLatex(latexContent);

    return TeXViewDocument(
      convertedContent,
      style: TeXViewStyle(
        margin: const TeXViewMargin.all(10),
        padding: const TeXViewPadding.all(10),
        borderRadius: const TeXViewBorderRadius.all(10),
        backgroundColor: Colors.white,
        fontStyle: TeXViewFontStyle(
          fontFamily: 'HandWrite', // Custom Font 적용
          fontSize: 14,
          sizeUnit: TeXViewSizeUnit.pt,
        ),
      ),
    );
  }

  /// 가독성을 향상시키기 위한 전체 변환 함수
  static String _convertToReadableLatex(String content) {
    // 1. ** **로 감싸진 텍스트를 굵게 변환
    String convertedContent = _convertBoldText(content);

    // 2. 번호가 있는 항목을 하이픈으로 대체
    convertedContent = _replaceNumberedItemsWithHyphen(convertedContent);

    // 3. 나머지 줄바꿈 처리를 적용하여 가독성 향상
    convertedContent = _applyLineBreaks(convertedContent);

    return convertedContent;
  }

  /// ** **로 감싸진 텍스트를 굵게 변환하는 함수
  static String _convertBoldText(String content) {
    // 정규식을 사용하여 **로 감싸진 텍스트를 <b>태그로 감싸진 형태로 변환
    return content.replaceAllMapped(RegExp(r'\*\*\s*(.*?)\s*\*\*'), (match) {
      return "<b>${match.group(1)}</b>";
    });
  }

  /// 숫자. 형식을 하이픈으로 변환하는 함수
  static String _replaceNumberedItemsWithHyphen(String content) {
    // "1. ", "2. "과 같은 숫자+점 형식을 "-"로 대체
    return content.replaceAllMapped(RegExp(r'(\d+\.\s*)'), (match) {
      return "- "; // 숫자와 점을 제거하고 하이픈과 공백으로 대체
    });
  }

  /// 긴 텍스트에 대해 적절한 줄바꿈과 간격을 추가하는 함수
  static String _applyLineBreaks(String content) {
    // 문장의 끝에 마침표, 느낌표, 물음표 뒤에 <br><br> 태그를 추가하여 두 줄 띄워줌
    return content.replaceAllMapped(RegExp(r'([.!?])(\s)'), (match) {
      return "${match.group(1)}<br><br>${match.group(2)}";
    });
  }
}