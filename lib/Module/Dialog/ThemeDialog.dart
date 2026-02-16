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
  bool _isSelectionInitialized = false;

  void _initializeSelection(ThemeHandler themeProvider) {
    if (_isSelectionInitialized) return;

    for (int i = 0; i < 24; i++) {
      final color = ThemeLockManager.getThemeColor(i);
      if (color.value == themeProvider.primaryColor.value) {
        _selectedColor = color;
        _selectedColorName = ThemeLockManager.getThemeName(i);
        _selectedIndex = i;
        _isSelectionInitialized = true;
        return;
      }
    }

    _selectedColor = themeProvider.primaryColor;
    _selectedColorName = '현재 테마';
    _selectedIndex = null;
    _isSelectionInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userInfo = userProvider.userInfoModel;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.82;
    _initializeSelection(themeProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxWidth: 430, maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeProvider.primaryColor.withOpacity(0.14),
                    themeProvider.primaryColor.withOpacity(0.04),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const StandardText(
                        text: '현재 선택',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _selectedColor ?? themeProvider.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: StandardText(
                          text: _selectedColorName ?? '선택 안 됨',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (_selectedColor != null && _selectedColorName != null) {
                          themeProvider.changePrimaryColor(
                              _selectedColor!, _selectedColorName!);
                        }
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const StandardText(
                        text: '적용하기',
                        fontSize: 14,
                        color: Colors.white,
                      ),
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
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.65,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black87 : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                backgroundColor: color,
                radius: 25,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            ),
          ),
          if (!isUnlocked)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}
