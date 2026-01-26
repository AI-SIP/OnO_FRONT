import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/Util/UrlLauncher.dart';
import 'package:provider/provider.dart';

import '../../Module/Dialog/ThemeDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import 'LoginScreen.dart';
import 'Widget/AccountActionButtons.dart';
import 'Widget/CompactActivityLevels.dart';
import 'Widget/SettingMenuButtons.dart';
import 'Widget/ThemeChangeButton.dart';
import 'Widget/UserLevelCard.dart';

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
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '${userProvider.userInfoModel?.name ?? '이름 없음'}님의 오답노트',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: !(userProvider.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: themeProvider.primaryColor,
              child: ListView(
                padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                children: [
                  SizedBox(height: screenHeight * 0.01),

                  // 유저 레벨 카드 (캐릭터 + 이름)
                  UserLevelCard(
                    userInfo: userProvider.userInfoModel,
                    themeProvider: themeProvider,
                    userName: userProvider.userInfoModel?.name ?? '이름 없음',
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // 총 경험치 바 + 활동 레벨 (통합)
                  CompactActivityLevels(
                    userInfo: userProvider.userInfoModel,
                    themeProvider: themeProvider,
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // 테마 변경 (독립)
                  ThemeChangeButton(
                    themeProvider: themeProvider,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ThemeDialog();
                        },
                      );
                    },
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // 설정 메뉴 버튼들 (이름 수정 포함)
                  SettingMenuButtons(
                    themeProvider: themeProvider,
                    onNameEditTap: () {
                      FirebaseAnalytics.instance
                          .logEvent(name: 'username_edit_button_click');
                      _showChangeNameDialog(
                          context, userProvider.userInfoModel?.name ?? '이름 없음');
                    },
                    onGuideTap: () {
                      UrlLauncher.launchGuidePageURL();
                    },
                    onFeedbackTap: () {
                      UrlLauncher.launchFeedbackPageURL();
                    },
                    onTermsTap: () {
                      UrlLauncher.launchUserTemPageURL();
                    },
                  ),

                  // 로그아웃/회원탈퇴 (흐릿한 텍스트)
                  AccountActionButtons(
                    onLogoutTap: () => showConfirmationDialog(
                      context,
                      '로그아웃',
                      '정말 로그아웃 하시겠습니까?\n(게스트 유저의 경우 모든 정보가 삭제됩니다.)',
                      () async {
                        await Provider.of<UserProvider>(context, listen: false)
                            .signOut();

                        Provider.of<ScreenIndexProvider>(context, listen: false)
                            .setSelectedIndex(0);

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    onDeleteAccountTap: () => showConfirmationDialog(
                      context,
                      '회원 탈퇴',
                      '정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                      () async {
                        await Provider.of<UserProvider>(context, listen: false)
                            .deleteAccount();

                        Provider.of<ScreenIndexProvider>(context, listen: false)
                            .setSelectedIndex(0);

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
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

  // 이름 변경 다이얼로그
  void _showChangeNameDialog(BuildContext context, String currentName) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
          content: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.001,
            ),
            child: TextField(
              controller: nameController,
              style:
                  standardTextStyle.copyWith(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: '수정할 이름을 입력하세요',
                hintStyle: standardTextStyle.copyWith(
                    color: ThemeHandler.desaturatenColor(Colors.black),
                    fontSize: 14),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03),
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
                  Navigator.pop(context);
                  await Provider.of<UserProvider>(context, listen: false)
                      .updateUser(
                    name: newName,
                    email: null,
                    identifier: null,
                  );
                }
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

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await Future.wait([
      userProvider.fetchUserInfo(),
    ]);
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
          title: StandardText(text: title, fontSize: 18, color: Colors.black),
          content: SizedBox(
            child:
                StandardText(text: message, fontSize: 15, color: Colors.black),
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
