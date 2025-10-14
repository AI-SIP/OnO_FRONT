import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/Util/UrlLauncher.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:provider/provider.dart';

import '../../Module/Dialog/ThemeDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
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
    final userProvider = Provider.of<UserProvider>(context);
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '설정',
          fontSize: 20,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: !(userProvider.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : Column(
              children: [
                Expanded(
                    child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: themeProvider.primaryColor,
                  child: ListView(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenHeight * 0.03),
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      _buildUserNameTile(
                        context: context,
                        userName: userProvider.userInfoModel?.name ?? '이름 없음',
                        themeProvider: themeProvider,
                      ),
                      const Divider(),
                      _buildProblemCountTile(
                        problemCount: problemsProvider.problemCount,
                        themeProvider: themeProvider,
                      ),
                      const Divider(),
                      _buildExperienceTile(
                        userInfo: userProvider.userInfoModel,
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
                )),
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

                          Provider.of<ScreenIndexProvider>(context,
                                  listen: false)
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

                          Provider.of<ScreenIndexProvider>(context,
                                  listen: false)
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
          padding: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.02, vertical: screenHeight * 0.01),
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

  // 경험치 및 레벨 정보 타일
  Widget _buildExperienceTile({
    required userInfo,
    required ThemeHandler themeProvider,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;

    if (userInfo == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
          child: StandardText(
            text: '활동 레벨',
            fontSize: 18,
            color: themeProvider.primaryColor,
          ),
        ),
        _buildExperienceRow(
          '출석',
          userInfo.attendanceLevel,
          userInfo.attendancePoint,
          Colors.pink[300]!,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.01),
        _buildExperienceRow(
          '오답노트 작성',
          userInfo.noteWriteLevel,
          userInfo.noteWritePoint,
          Colors.purple[300]!,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.01),
        _buildExperienceRow(
          '오답노트 복습',
          userInfo.problemPracticeLevel,
          userInfo.problemPracticePoint,
          Colors.green[400]!,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.01),
        _buildExperienceRow(
          '복습노트 복습',
          userInfo.notePracticeLevel,
          userInfo.notePracticePoint,
          Colors.blue[300]!,
          screenHeight,
        ),
      ],
    );
  }

  // 각 경험치 항목 행
  Widget _buildExperienceRow(
    String category,
    int level,
    int point,
    Color color,
    double screenHeight,
  ) {
    // 다음 레벨까지 필요한 경험치 (예: 100포인트마다 1레벨)
    int requiredPoint = level * 100;
    double progress = requiredPoint > 0 ? point / requiredPoint : 0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: StandardText(
            text: category,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        SizedBox(width: screenHeight * 0.01),
        StandardText(
          text: 'Lv.$level',
          fontSize: 14,
          color: color,
        ),
        SizedBox(width: screenHeight * 0.01),
        Expanded(
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        SizedBox(width: screenHeight * 0.01),
        StandardText(
          text: '$point/$requiredPoint',
          fontSize: 12,
          color: Colors.grey[600]!,
        ),
      ],
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
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03, vertical: screenHeight * 0.01),
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
              horizontal: screenWidth * 0.001, // 좌우 여백 추가
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
    // 1. 필요한 Provider를 listen: false로 가져옵니다.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    // 2. 각 Provider의 데이터를 새로고침하는 메서드를 호출합니다.
    // (UserProvider와 ProblemsProvider에 해당 메서드가 있다고 가정합니다.
    // 만약 없다면, 해당 Provider에 데이터를 다시 불러오는 로직을 추가해야 합니다.)
    await Future.wait([
      userProvider.fetchUserInfo(), // 사용자 정보를 다시 불러오는 비동기 함수
      //problemsProvider.getUserProblemCount(), // 문제 개수를 다시 불러오는 비동기 함수
      // 필요하다면 다른 데이터 로딩 함수 추가
    ]);

    // 새로고침 완료 (Future.wait이 완료될 때까지 기다립니다.)
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
