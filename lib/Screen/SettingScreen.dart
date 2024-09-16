import 'package:flutter/material.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Service/Auth/AuthService.dart';
import '../Service/ScreenUtil/SettingScreenService.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late SettingScreenService _settingScreenService;

  @override
  void initState() {
    super.initState();
    _settingScreenService = SettingScreenService();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 여백 늘림
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildUserNameTile(
                    context: context,
                    userName: authService.userName,
                    themeProvider: themeProvider,
                  ),
                  const Divider(),
                  _buildSettingItemWithColor(
                    title: '테마 변경',
                    subtitle: '앱의 테마를 변경하세요.',
                    themeColor: themeProvider.primaryColor, // 현재 테마 색상
                    context: context,
                    onTap: () {
                      _settingScreenService.showThemeDialog(context);
                    },
                  ),
                  const Divider(),
                  _buildSettingItem(
                    title: '의견 남기기',
                    subtitle: '앱에 대한 의견을 보내주세요.',
                    context: context,
                    onTap: () {
                      _settingScreenService.openFeedbackForm();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(
                    context,
                    '로그아웃',
                    Colors.white,
                    Colors.red,
                        () => _settingScreenService.showConfirmationDialog(
                      context,
                      '로그아웃',
                      '정말 로그아웃 하시겠습니까?\n(게스트 유저의 경우 모든 정보가 삭제됩니다.)',
                          () => _settingScreenService.logout(context),
                    ),
                  ),
                  _buildBottomButton(
                    context,
                    '회원 탈퇴',
                    Colors.red,
                    Colors.white,
                        () => _settingScreenService.showConfirmationDialog(
                      context,
                      '회원 탈퇴',
                      '정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                          () => _settingScreenService.deleteAccount(context),
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

  // 유저 이름 타일
  Widget _buildUserNameTile({
    required BuildContext context,
    required String userName,
    required ThemeHandler themeProvider,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      title: DecorateText(
        text: '$userName님',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      trailing: TextButton(
        onPressed: () {
          _showChangeNameDialog(context);
        },
        child: DecorateText(
          text: '이름 수정',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  // 테마 색상을 보여주는 설정 항목
  Widget _buildSettingItemWithColor({
    required String title,
    required String subtitle,
    required Color themeColor,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      title: DecorateText(
        text: title,
        fontSize: 22,
        color: themeColor,
      ),
      subtitle: DecorateText(
        text: subtitle,
        fontSize: 16,
        color: themeColor.withOpacity(0.6),
      ),
      trailing: Container(
        width: 40,  // 원의 크기를 키움
        height: 40,
        decoration: BoxDecoration(
          color: themeColor,
          shape: BoxShape.circle,
        ),
      ),
      onTap: onTap,
    );
  }

  // 일반 설정 항목
  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required BuildContext context,
    VoidCallback? onTap,
  }) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      title: DecorateText(
        text: title,
        fontSize: 22,
        color: themeProvider.primaryColor,
      ),
      subtitle: DecorateText(
        text: subtitle,
        fontSize: 16,
        color: themeProvider.primaryColor.withOpacity(0.6),
      ),
      onTap: onTap,
    );
  }

  // 하단 버튼 스타일
  Widget _buildBottomButton(BuildContext context, String text, Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: DecorateText(
        text: text,
        fontSize: 20,
        color: textColor,
      ),
    );
  }

  // 이름 변경 다이얼로그
  void _showChangeNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: '이름 수정',
            fontSize: 24,
            color: Provider.of<ThemeHandler>(context, listen: false).primaryColor,
          ),
          content: TextField(
            decoration: const InputDecoration(
              hintText: '새 이름을 입력하세요',
            ),
            // 이름 입력 처리 로직
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                // 이름 수정 로직
                Navigator.pop(context);
              },
              child: DecorateText(
                text: '확인',
                fontSize: 18,
                color: Provider.of<ThemeHandler>(context, listen: false).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}