import 'dart:ui';

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
import 'Widget/ReviewReportScreen.dart';
import 'Widget/SettingMenuButtons.dart';
import 'Widget/ThemeChangeButton.dart';
import 'Widget/StreakCard.dart';
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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTabletLandscape =
        mediaQuery.size.shortestSide >= 600 && screenWidth > screenHeight;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '${userProvider.userInfoModel?.name ?? '이름 없음'}님의 오답노트',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.settings, color: themeProvider.primaryColor),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const _MyPageSettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
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
                  if (isTabletLandscape)
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: UserLevelCard(
                                userInfo: userProvider.userInfoModel,
                                themeProvider: themeProvider,
                                userName:
                                    userProvider.userInfoModel?.name ?? '이름 없음',
                                horizontalMarginFactor: 0,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: StreakCard(
                                themeProvider: themeProvider,
                                horizontalMarginFactor: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    UserLevelCard(
                      userInfo: userProvider.userInfoModel,
                      themeProvider: themeProvider,
                      userName: userProvider.userInfoModel?.name ?? '이름 없음',
                    ),
                  ],
                  if (!isTabletLandscape) ...[
                    SizedBox(height: screenHeight * 0.01),
                    StreakCard(themeProvider: themeProvider),
                  ],
                  SizedBox(height: screenHeight * 0.01),
                  _buildReviewReportButton(themeProvider),
                  SizedBox(height: screenHeight * 0.01),
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

  Widget _buildReviewReportButton(
    ThemeHandler themeProvider, {
    double horizontalMarginFactor = 0.04,
    bool compact = false,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final isTabletLandscape = isTablet && screenWidth > screenHeight;

    const dummyBars = [0.38, 0.55, 0.42, 0.78, 0.60, 0.88, 0.70];
    const dummyCounts = [4, 6, 5, 9, 7, 10, 8];
    const dummyLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * horizontalMarginFactor,
        vertical: screenHeight * 0.005,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ReviewReportScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            screenHeight * 0.018,
            isTabletLandscape ? screenHeight * 0.030 : screenHeight * 0.018,
            screenHeight * 0.018,
            isTabletLandscape ? screenHeight * 0.024 : screenHeight * 0.014,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.stacked_bar_chart_rounded,
                      color: themeProvider.primaryColor,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: screenHeight * 0.015),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardText(
                          text: compact ? '학습\n리포트' : '학습 리포트',
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          StandardText(
                            text: '복습 추이와 약점 분석을 확인해요',
                            fontSize: 11,
                            color: Colors.grey[700]!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              SizedBox(height: isTabletLandscape ? screenHeight * 0.024 : screenHeight * 0.014),
              _buildMosaicTrendPreview(
                themeProvider,
                dummyBars,
                dummyCounts,
                dummyLabels,
                graphHeight: isTabletLandscape ? 140.0 : 100.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosaicTrendPreview(
    ThemeHandler themeProvider,
    List<double> bars,
    List<int> counts,
    List<String> labels, {
    double graphHeight = 100.0,
  }) {
    final maxBar = bars.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: graphHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(bars.length, (index) {
          final isPeak = bars[index] == maxBar;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const labelHeight = 14.0;
                      const gap = 4.0;
                      const minBarHeight = 4.0;
                      final usableBarHeight =
                          (constraints.maxHeight - labelHeight - gap)
                              .clamp(0.0, constraints.maxHeight);
                      final rawBarHeight = usableBarHeight * bars[index];
                      final barHeight = rawBarHeight < minBarHeight
                          ? minBarHeight
                          : (rawBarHeight > usableBarHeight
                              ? usableBarHeight
                              : rawBarHeight);
                      final numberBottom = barHeight + gap;

                      return Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 16,
                              height: barHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    themeProvider.primaryColor,
                                    themeProvider.lightPrimaryColor,
                                  ],
                                ),
                                boxShadow: isPeak
                                    ? [
                                        BoxShadow(
                                          color: themeProvider.primaryColor
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: numberBottom,
                            child: Center(
                              child: SizedBox(
                                height: labelHeight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: 3.5,
                                      sigmaY: 3.5,
                                    ),
                                    child: StandardText(
                                      text: counts[index].toString(),
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'PretendardBold',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 16,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StandardText(
                        text: labels[index],
                        fontSize: 11,
                        color: Colors.grey[700]!,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PretendardBold',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await Future.wait([
      userProvider.fetchUserInfo(),
    ]);
  }
}

class _MyPageSettingsScreen extends StatelessWidget {
  const _MyPageSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenIndexProvider =
        Provider.of<ScreenIndexProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '설정',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
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
                const SizedBox(height: 8),
                SettingMenuButtons(
                  themeProvider: themeProvider,
                  onNameEditTap: () {
                    FirebaseAnalytics.instance
                        .logEvent(name: 'username_edit_button_click');
                    _showChangeNameDialog(
                      context,
                      userProvider.userInfoModel?.name ?? '이름 없음',
                    );
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
                  notificationEnabled:
                      userProvider.userInfoModel?.notificationEnabled ?? true,
                  onNotificationChanged: (value) async {
                    try {
                      await Provider.of<UserProvider>(context, listen: false)
                          .updateNotificationSettings(value);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: StandardText(
                            text: '알림 설정 변경에 실패했습니다. 다시 시도해주세요.',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AccountActionButtons(
              onLogoutTap: () => _showConfirmationDialog(
                context,
                '로그아웃',
                '정말 로그아웃 하시겠습니까?\n(게스트 유저의 경우 모든 정보가 삭제됩니다.)',
                () async {
                  await userProvider.signOut();
                  screenIndexProvider.setSelectedIndex(0);

                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              onDeleteAccountTap: () => _showConfirmationDialog(
                context,
                '회원 탈퇴',
                '정말 회원 탈퇴 하시겠습니까?\n그동안 작성했던 모든 오답노트 및 개인정보가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                () async {
                  await userProvider.deleteAccount();
                  screenIndexProvider.setSelectedIndex(0);

                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showChangeNameDialog(BuildContext context, String currentName) {
  final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withValues(alpha: 0.1),
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
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor.withValues(alpha: 0.5),
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
                        await Provider.of<UserProvider>(context, listen: false)
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

void _showConfirmationDialog(BuildContext context, String title, String message,
    VoidCallback onConfirm) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
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
              StandardText(
                text: message,
                fontSize: 15,
                color: Colors.black87,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                      onPressed: () {
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
