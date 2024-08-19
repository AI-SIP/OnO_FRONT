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
  late SettingScreenService _settingScreenService; // Declare service

  @override
  void initState() {
    super.initState();
    _settingScreenService = SettingScreenService(); // Initialize service
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (authService.isLoggedIn == LoginStatus.login) ...[
                _buildWelcomeText(authService, themeProvider),
                const SizedBox(height: 40),
                _buildButton(
                  context,
                  '테마 변경',
                  Colors.white,
                  themeProvider.primaryColor,
                  () => _settingScreenService.showThemeDialog(context),
                ),
                const SizedBox(height: 20),
                _buildButton(
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
                const SizedBox(height: 20),
                _buildButton(
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
              ] else ...[
                DecorateText(
                  text: '로그인 해주세요!',
                  fontSize: 24,
                  color: themeProvider.primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DecorateText _buildWelcomeText(
      AuthService authService, ThemeHandler themeProvider) {
    return DecorateText(
      text: '${authService.userName}님 환영합니다!!',
      fontSize: 30,
      color: themeProvider.primaryColor,
    );
  }

  Widget _buildButton(BuildContext context, String text, Color backgroundColor,
      Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
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
      ),
    );
  }
}
