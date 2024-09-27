// TemplateSelectionScreen.dart
import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/StandardText.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/HandWriteText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: HandWriteText(
          text: '오답노트 템플릿 선택',
          fontSize: 24,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              children: [
                const SizedBox(height: 10),
                _buildTemplateItem(
                  context: context,
                  title: '심플 템플릿',
                  descriptions: [
                    '추천 과목 : 국어, 영어',
                    '빠르게 오답노트를 등록하고, 편리한 복습을 하고 싶은 분들을 위한 템플릿입니다.',
                  ], // description을 여러 필드로 분리
                  themeProvider: themeProvider,
                ),
                const Divider(),
                _buildTemplateItem(
                  context: context,
                  title: '클린 템플릿',
                  descriptions: [
                    '추천 과목 : 사회 탐구',
                    '필기 제거 기능을 통해 효율적인 복습을 하고 싶은 분들을 위한 템플릿입니다.',
                  ], // description을 여러 필드로 분리
                  themeProvider: themeProvider,
                ),
                const Divider(),
                _buildTemplateItem(
                  context: context,
                  title: '스페셜 템플릿',
                  descriptions: [
                    '추천 과목 : 수학, 과학',
                    '필기 제거 기능과 AI 문제 분석 기능을 통해 고도화된 복습을 하고 싶은 분들을 위한 템플릿입니다',
                  ], // description을 여러 필드로 분리
                  themeProvider: themeProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem({
    required BuildContext context,
    required String title,
    required List<String> descriptions, // 여러 필드로 분리된 description 리스트
    required ThemeHandler themeProvider,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      title: HandWriteText(
        text: title,
        fontSize: 20,
        color: themeProvider.darkPrimaryColor,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: descriptions.map((desc) {
          return Padding(
            padding: const EdgeInsets.only(top: 4.0), // 각 필드 사이에 여백 추가
            child: StandardText(
              text: desc,
              fontSize: 14,
              color: themeProvider.primaryColor.withOpacity(0.6),
            ),
          );
        }).toList(),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 선택됨')),
        );
      },
    );
  }
}