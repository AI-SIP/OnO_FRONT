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
          fontSize: 18,
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
                clipBehavior: Clip.none,
                padding: EdgeInsets.only(
                    bottom: screenHeight * 0.01, top: screenHeight * 0.02),
                children: [
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

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '이름 수정',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 입력 필드
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: standardTextStyle.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '수정할 이름을 입력하세요',
                    hintStyle: standardTextStyle.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                      onPressed: () async {
                        String newName = nameController.text;
                        if (newName.isNotEmpty) {
                          Navigator.pop(context);
                          await Provider.of<UserProvider>(context,
                                  listen: false)
                              .updateUser(
                            name: newName,
                            email: null,
                            identifier: null,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const StandardText(
                        text: '수정',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: title,
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
                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: Colors.red,
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
