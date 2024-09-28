import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/HandWriteText.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Image/ColorPicker/ImageColorPickerHandler.dart';
import '../GlobalModule/Image/ImagePickerHandler.dart';
import '../GlobalModule/Theme/StandardText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Model/TemplateType.dart';
import '../Provider/FoldersProvider.dart';

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
      title: HandWriteText(
        text: templateType.displayName,
        fontSize: 24,
        color: themeProvider.darkPrimaryColor,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: templateType.description.map((desc) {
          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: StandardText(
              text: desc,
              fontSize: 16,
              color: themeProvider.primaryColor.withOpacity(0.6),
            ),
          );
        }).toList(),
      ),
        onTap: () {
          final imagePickerHandler = ImagePickerHandler();
          imagePickerHandler.showImagePicker(context, (pickedFile) async {
            if (pickedFile != null) {

              List<Map<String, int>?>? selectedColors;

              // TemplateType이 clean이나 special인 경우 색상 선택 화면 표시
              if (templateType == TemplateType.clean || templateType == TemplateType.special) {
                final colorPickerHandler = ImageColorPickerHandler();
                selectedColors = await colorPickerHandler.showColorPicker(context, pickedFile.path);
              }


              // 이미지 전송 로직
              await Provider.of<FoldersProvider>(context, listen: false)
                  .uploadProblemImage(pickedFile, templateType, selectedColors);

              Navigator.pushNamed(context, '/problemRegister', arguments: templateType);
            }
          });
        }
    );
  }
}