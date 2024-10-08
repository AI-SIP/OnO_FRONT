import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../GlobalModule/Image/ColorPicker/ImageColorPickerHandler.dart';
import '../../GlobalModule/Image/ImagePickerHandler.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemModel.dart';
import '../../Model/TemplateType.dart';
import '../../Provider/FoldersProvider.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: AppBar(
        title: StandardText(
          text: '오답노트 템플릿 선택',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              children: TemplateType.values.map((templateType) {
                return Column(
                  children: [
                    _buildTemplateItem(
                      context: context,
                      templateType: templateType,
                      themeProvider: themeProvider,
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem({
    required BuildContext context,
    required TemplateType templateType,
    required ThemeHandler themeProvider,
  }) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        leading: _getTemplateIcon(templateType, themeProvider), // 템플릿에 맞는 아이콘 추가
        title: StandardText(
          text: templateType.displayName,
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: templateType.description.map((desc) {
            return Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: _getHighlightedDescription(desc, themeProvider),
            );
          }).toList(),
        ),
        onTap: () {
          FirebaseAnalytics.instance.logEvent(name: 'template_selection_${templateType.name}');

          final imagePickerHandler = ImagePickerHandler();
          imagePickerHandler.showImagePicker(context, (pickedFile) async {
            if (pickedFile != null) {
              List<Map<String, int>?>? selectedColors;

              // TemplateType이 clean이나 special인 경우 색상 선택 화면 표시
              if (templateType == TemplateType.clean || templateType == TemplateType.special) {
                final colorPickerHandler = ImageColorPickerHandler();
                selectedColors = await colorPickerHandler.showColorPicker(context, pickedFile.path);
              }

              final result = await Provider.of<FoldersProvider>(context, listen: false)
                  .uploadProblemImage(pickedFile);

              // `result`에 받은 값을 사용하여 화면 이동
              if (result != null) {
                final problemId = result['problemId'];
                final problemImageUrl = result['problemImageUrl'];

                final problemModel = ProblemModel(
                  problemId: problemId,
                  problemImageUrl: problemImageUrl,
                  templateType: templateType,
                );

                Navigator.pushNamed(
                  context,
                  '/problemRegister',
                  arguments: {
                    'problemModel' : problemModel,
                    'isEditMode' : false,
                    'colors' : selectedColors,
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const StandardText(text: '문제 이미지 업로드에 실패했습니다. 다시 시도해주세요.', color: Colors.white,), backgroundColor: themeProvider.primaryColor,),
                );
              }
            }
          });
        }
    );
  }

  // 템플릿 타입에 따른 아이콘 설정
  Widget _getTemplateIcon(TemplateType templateType, ThemeHandler themeProvider) {
    switch (templateType) {
      case TemplateType.simple:
        return Icon(Icons.library_books_rounded, color: themeProvider.primaryColor);
      case TemplateType.clean:
        return Icon(Icons.brush, color: themeProvider.primaryColor);
      case TemplateType.special:
        return Icon(Icons.auto_awesome, color: themeProvider.primaryColor);
    }
  }

  Widget _getHighlightedDescription(String desc, ThemeHandler themeProvider) {
    List<TextSpan> spans = [];

    // **로 감싸진 텍스트 부분을 찾아서 강조
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final matches = regex.allMatches(desc);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    int lastMatchEnd = 0;

    for (final match in matches) {
      // 강조되지 않은 부분 추가
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: desc.substring(lastMatchEnd, match.start),
          style: standardTextStyle.copyWith(
              color: themeProvider.primaryColor,
              fontSize: 14,
          ),
        ));
      }

      // 강조된 부분 추가
      spans.add(TextSpan(
        text: match.group(1), // **로 감싸진 텍스트
        style: standardTextStyle.copyWith(
            color: themeProvider.darkPrimaryColor,
            fontSize: 14
        ),
      ));

      lastMatchEnd = match.end;
    }

    // 마지막 남은 텍스트 추가
    if (lastMatchEnd < desc.length) {
      spans.add(TextSpan(
        text: desc.substring(lastMatchEnd),
        style: standardTextStyle.copyWith(
            color: themeProvider.primaryColor,
            fontSize: 14
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}