import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Provider/UserProvider.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';
import '../Theme/ThemeLockManager.dart';

class ThemeDialog extends StatefulWidget {
  @override
  _ThemeDialogState createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<ThemeDialog> {
  Color? _selectedColor;
  String? _selectedColorName;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userInfo = userProvider.userInfoModel;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const StandardText(
        text: '테마 색상 선택',
        fontSize: 20,
        color: Colors.black,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Ensures the dialog fits content size
          children: [
            const SizedBox(height: 20), // Add vertical spacing
            SizedBox(
              height: 550, // 크기 증가
              width: 350, // 크기 증가
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Number of columns
                  crossAxisSpacing: 12.0, // 간격 증가
                  mainAxisSpacing: 12.0, // 간격 증가
                ),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final color = ThemeLockManager.getThemeColor(index);
                  final colorName = ThemeLockManager.getThemeName(index);
                  final isUnlocked =
                      ThemeLockManager.isThemeUnlocked(index, userInfo);

                  return _buildColorCircle(color, colorName, index, isUnlocked);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const StandardText(
            text: '취소',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedColor != null) {
              // Change the PrimaryColor to the selected color
              themeProvider.changePrimaryColor(
                  _selectedColor!, _selectedColorName!);

              Navigator.of(context).pop();
            }
          },
          child: StandardText(
            text: '확인',
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(
      Color color, String colorName, int index, bool isUnlocked) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          setState(() {
            _selectedColor = color;
            _selectedColorName = colorName;
            _selectedIndex = index;
          });
        } else {
          // 잠긴 테마를 클릭했을 때 필요 조건 표시
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final userInfo = userProvider.userInfoModel;
          final message =
              ThemeLockManager.getRequiredLevelMessage(index, userInfo);
          final themeProvider =
              Provider.of<ThemeHandler>(context, listen: false);

          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    Icon(Icons.lock, color: color, size: 24),
                    const SizedBox(width: 8),
                    const StandardText(
                      text: '잠금된 테마',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ],
                ),
                content: StandardText(
                  text: message,
                  fontSize: 16,
                  color: Colors.black,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: StandardText(
                      text: '확인',
                      fontSize: 16,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 잠금 상태일 때 반투명 처리 (투명도 0.65로 증가하여 더 잘 보이게)
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.65,
            child: CircleAvatar(
              backgroundColor: color,
              radius: 28, // 크기 증가 (16 → 28)
              child: isSelected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 24) // 아이콘 크기도 증가
                  : null,
            ),
          ),
          // 잠금 아이콘 (어두운 배경과 함께)
          if (!isUnlocked)
            Container(
              width: 56, // 원 크기에 맞춰 증가
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35), // 투명도 약간 증가
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 24, // 자물쇠 아이콘 크기 증가
              ),
            ),
        ],
      ),
    );
  }
}
