import 'package:flutter/material.dart';
import 'package:ono/GlobalModule/Theme/ThemeHandler.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Theme/ThemeDialog.dart';
import '../Service/AuthService.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  void _showLogoutDialog(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DecorateText(text: '로그아웃', fontSize: 24, color: themeProvider.primaryColor),
          content: DecorateText(
              text: '정말 로그아웃 하시겠습니까?\n(게스트 유저의 경우 모든 정보가 삭제됩니다.)',
              fontSize: 20, color: themeProvider.primaryColor),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();
                _showSuccessDialog(context, '로그아웃에 성공했습니다.');
              },
              child: const DecorateText(
                text: '로그아웃',
                fontSize: 20,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DecorateText(text: '회원 탈퇴', fontSize: 24, color: themeProvider.primaryColor),
          content:  DecorateText(
              text:
                  '정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
              fontSize: 20, color: themeProvider.primaryColor),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const DecorateText(
                  text: '취소',
                  fontSize: 20,
                  color: Colors.black,
                )),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthService>(context, listen: false)
                    .deleteAccount();
                //_showSuccessDialog(context, '회원 탈퇴에 성공했습니다.');
              },
              child: const DecorateText(
                text: '탈퇴',
                fontSize: 20,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ThemeDialog();
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {

    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DecorateText(
          text: message,
          fontSize: 20,
          color: Colors.white,
        ),
        backgroundColor: themeProvider.primaryColor,
      ),
    );
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
              if (authService.isLoggedIn) ...[
                DecorateText(
                    text: '${authService.userName}님 환영합니다!!', fontSize: 30, color: themeProvider.primaryColor),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _showThemeDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: themeProvider.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: DecorateText(
                    text: '테마 변경',
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const DecorateText(
                    text: '로그아웃',
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20), // 버튼 간 간격 추가
                ElevatedButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                  ),
                  child: const DecorateText(
                    text: '회원 탈퇴',
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                DecorateText(text: '로그인 해주세요!', fontSize: 24, color: themeProvider.primaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

