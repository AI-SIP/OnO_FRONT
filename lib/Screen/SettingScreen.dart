import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Service/AuthService.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃', style: TextStyle(
              fontFamily: 'font1',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green)),
          content: const Text('정말 로그아웃 하시겠습니까?', style: TextStyle(
              fontFamily: 'font1',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소', style: TextStyle(
                  fontFamily: 'font1',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();
                _showSuccessDialog(context, '로그아웃에 성공했습니다.');
              },
              child: const Text('로그아웃', style: TextStyle(
                  fontFamily: 'font1',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴', style: TextStyle(
              fontFamily: 'font1',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green)),
          content: const Text('정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.', style: TextStyle(
              fontFamily: 'font1',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소', style: TextStyle(
                  fontFamily: 'font1',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthService>(context, listen: false)
                    .deleteAccount();
                _showSuccessDialog(context, '회원 탈퇴에 성공했습니다.');
              },
              child: const Text('탈퇴', style: TextStyle(
                  fontFamily: 'font1',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'font1',
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (authService.isLoggedIn) ...[
                Text(
                  '${authService.userName}님 환영합니다!',
                  style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'font1',
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  '로그인 한 계정: ${authService.userEmail}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'font1',
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

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
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontFamily: 'font1',
                        fontWeight: FontWeight.bold),
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
                  child: const Text(
                    '회원 탈퇴',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'font1',
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                const Text('로그인 해주세요!',
                    style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'font1',
                        fontSize: 24,
                        fontWeight: FontWeight.bold))
              ],
            ],
          ),
        ),
      ),
    );
  }
}
