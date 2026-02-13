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

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const StandardText(
                    text: '테마 색상 선택',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            // 컨텐츠
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 480,
                width: 350,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
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
            ),
            // 액션 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const StandardText(
                      text: '취소',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      if (_selectedColor != null) {
                        themeProvider.changePrimaryColor(
                            _selectedColor!, _selectedColorName!);
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const StandardText(
                            text: '잠금된 테마',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 내용
                      StandardText(
                        text: message,
                        fontSize: 15,
                        color: Colors.black87,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // 버튼
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: themeProvider.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const StandardText(
                            text: '확인',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
