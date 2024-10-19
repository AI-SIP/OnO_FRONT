import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../GlobalModule/Theme/SnackBarDialog.dart';
import '../GlobalModule/Theme/StandardText.dart';
import '../GlobalModule/Theme/ThemeDialog.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: !(authService.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    children: [
                      const SizedBox(height: 10),
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
                        title: '의견 남기기',
                        subtitle: '앱에 대한 의견을 보내주세요.',
                        context: context,
                        onTap: () {
                          FirebaseAnalytics.instance.logEvent(
                              name: 'feedback_button_click',
                              parameters: {
                                'url': AppConfig.feedbackPageUrl,
                              });
                          openFeedbackForm();
                        },
                      ),
                      const Divider(),
                      _buildSettingItem(
                        title: 'OnO 이용약관',
                        subtitle: '',
                        context: context,
                        onTap: () {
                          FirebaseAnalytics.instance.logEvent(
                              name: 'userTerm_button_click',
                              parameters: {
                                'url': AppConfig.userTermPageUrl,
                              });
                          openUserTermPage();
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
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
    return Center(
      child: StandardText(
        text: '로그인을 통해 설정을 변경해보세요!',
        fontSize: 16,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
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
          foregroundColor: themeProvider.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: themeProvider.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: StandardText(
          text: '이름 수정',
          fontSize: 14,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  // 작성한 문제 수를 보여주는 타일
  Widget _buildProblemCountTile({
    required int problemCount,
    required ThemeHandler themeProvider,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      title: StandardText(
        text: '작성한 오답노트 수',
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      trailing: StandardText(
        text: problemCount.toString(),
        fontSize: 18,
        color: themeProvider.primaryColor,
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
      title: StandardText(
        text: title,
        fontSize: 18,
        color: themeColor,
      ),
      subtitle: StandardText(
        text: subtitle,
        fontSize: 14,
        color: themeColor.withOpacity(0.6),
      ),
      trailing: Container(
        width: 40,
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
      title: StandardText(
        text: title,
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      subtitle: StandardText(
        text: subtitle,
        fontSize: 14,
        color: themeProvider.primaryColor.withOpacity(0.6),
      ),
      onTap: onTap,
    );
  }

  // 하단 버튼 스타일
  Widget _buildBottomButton(BuildContext context, String text,
      Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: StandardText(
        text: text,
        fontSize: 16,
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
            text: '이름 수정',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 화면 가로의 80%로 설정
            child: TextField(
              controller: nameController,
              style: standardTextStyle.copyWith(
                  color: themeProvider.primaryColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: '수정할 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                    color: themeProvider.desaturateColor, fontSize: 14),
                border: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
              text: title, fontSize: 18, color: themeProvider.primaryColor),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 화면 가로의 80%로 설정
            child: StandardText(
                text: message, fontSize: 15, color: themeProvider.primaryColor),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const StandardText(
                  text: '취소',
                  fontSize: 14,
                  color: Colors.black,
                )),
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: StandardText(
                  text: '확인',
                  fontSize: 14,
                  color: themeProvider.primaryColor,
                )),
          ],
        );
      },
    );
  }

  Future<void> openFeedbackForm() async {
    Uri url = Uri.parse(AppConfig.feedbackPageUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> openUserTermPage() async {
    Uri url = Uri.parse(AppConfig.userTermPageUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}
