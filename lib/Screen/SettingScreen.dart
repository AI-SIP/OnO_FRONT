import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/GlobalModule/Util/UrlLauncher.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../GlobalModule/Theme/StandardText.dart';
import '../GlobalModule/Theme/ThemeDialog.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Provider/ScreenIndexProvider.dart';
import '../Provider/UserProvider.dart';
import 'LoginScreen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<UserProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: StandardText(
          text: '설정',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: !(authService.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.03),
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      _buildUserNameTile(
                        context: context,
                        userName: userProvider.userName ?? '이름 없음',
                        themeProvider: themeProvider,
                      ),
                      const Divider(),
                      _buildProblemCountTile(
                        problemCount: userProvider.problemCount ?? 0,
                        themeProvider: themeProvider,
                      ),
                      const Divider(),
                      _buildSettingItemWithColor(
                        title: '테마 변경',
                        subtitle: '앱의 테마를 변경하세요.',
                        themeColor: themeProvider.primaryColor,
                        context: context,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ThemeDialog();
                            },
                          );
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'OnO 가이드 페이지',
                        subtitle: 'OnO의 사용 방법을 알아보세요.',
                        context: context,
                        onTap: () {
                          UrlLauncher.launchGuidePageURL();
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: '의견 남기기',
                        subtitle: '앱에 대한 의견을 보내주세요.',
                        context: context,
                        onTap: () {
                          UrlLauncher.launchFeedbackPageURL();
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'OnO 이용약관',
                        subtitle: 'OnO의 이용 약관을 확인하세요.',
                        context: context,
                        onTap: () {
                          UrlLauncher.launchUserTemPageURL();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomButton(
                        context,
                        '로그아웃',
                        Colors.white,
                        Colors.red,
                        () => showConfirmationDialog(context, '로그아웃',
                            '정말 로그아웃 하시겠습니까?\n(게스트 유저의 경우 모든 정보가 삭제됩니다.)',
                            () async {
                          await Provider.of<UserProvider>(context,
                                  listen: false)
                              .signOut();

                          Provider.of<ScreenIndexProvider>(context, listen: false)
                              .setSelectedIndex(0);

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        }),
                      ),
                      _buildBottomButton(
                        context,
                        '회원 탈퇴',
                        Colors.red,
                        Colors.white,
                        () => showConfirmationDialog(context, '회원 탈퇴',
                            '정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                            () async {
                          await Provider.of<UserProvider>(context,
                                  listen: false)
                              .deleteAccount();

                          Provider.of<ScreenIndexProvider>(context, listen: false)
                              .setSelectedIndex(0);

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginPrompt(ThemeHandler themeProvider) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: StandardText(
        text: '로그인을 통해 설정을 변경해보세요!',
        fontSize: screenHeight * 0.016,
        color: themeProvider.primaryColor,
      ),
    );
  }

  // 유저 이름 타일
  Widget _buildUserNameTile({
    required BuildContext context,
    required String userName,
    required ThemeHandler themeProvider,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: StandardText(
        text: '$userName님',
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      trailing: ElevatedButton(
        onPressed: () {
          FirebaseAnalytics.instance
              .logEvent(name: 'username_edit_button_click');
          _showChangeNameDialog(context, userName);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Colors.black),
          padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02, vertical: screenHeight * 0.01),
        ),
        child: const StandardText(
          text: '이름 수정',
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }

  // 작성한 문제 수를 보여주는 타일
  Widget _buildProblemCountTile({
    required int problemCount,
    required ThemeHandler themeProvider,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: StandardText(
        text: '작성한 오답노트 수',
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      trailing: StandardText(
        text: problemCount.toString(),
        fontSize: 18,
        color: Colors.black,
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
    double screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: StandardText(
        text: title,
        fontSize: 18,
        color: themeColor,
      ),
      subtitle: StandardText(
        text: subtitle,
        fontSize: 14,
        color: ThemeHandler.desaturatenColor(themeColor),
      ),
      trailing: Container(
        width: screenHeight * 0.04,
        height: screenHeight * 0.04,
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
    double screenHeight = MediaQuery.of(context).size.height;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: StandardText(
        text: title,
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      subtitle: StandardText(
        text: subtitle,
        fontSize: 14,
        color: themeProvider.desaturateColor,
      ),
      onTap: onTap,
    );
  }

  // 하단 버튼 스타일
  Widget _buildBottomButton(BuildContext context, String text,
      Color backgroundColor, Color textColor, VoidCallback onPressed) {
    double screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.03, vertical: screenHeight * 0.015),
      ),
      child: StandardText(
        text: text,
        fontSize: screenHeight * 0.016,
        color: textColor,
      ),
    );
  }

  // 이름 변경 다이얼로그
  void _showChangeNameDialog(BuildContext context, String currentName) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    double screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
            text: '이름 수정',
            fontSize: 18,
            color: Colors.black,
          ),
          content: SizedBox(
            child: TextField(
              controller: nameController,
              style: standardTextStyle.copyWith(
                  color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: '수정할 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                    color: ThemeHandler.desaturatenColor(Colors.black), fontSize: 14),
                border: OutlineInputBorder(
                  borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  const BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenHeight * 0.012),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                String newName = nameController.text;
                if (newName.isNotEmpty) {
                  // 이름 업데이트 요청, 나머지 필드는 null로 보냄
                  await userProvider.updateUser(
                    name: newName,
                    email: null,
                    identifier: null,
                    userType: null,
                  );
                }
                Navigator.pop(context);
              },
              child: StandardText(
                text: '수정',
                fontSize: 14,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  void showConfirmationDialog(BuildContext context, String title,
      String message, VoidCallback onConfirm) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    double screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
              text: title, fontSize: 18, color: Colors.black),
          content: SizedBox(
            child: StandardText(
                text: message, fontSize: 15, color: Colors.black),
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
                )),
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const StandardText(
                  text: '확인',
                  fontSize: 16,
                  color: Colors.red,
                )),
          ],
        );
      },
    );
  }
}
