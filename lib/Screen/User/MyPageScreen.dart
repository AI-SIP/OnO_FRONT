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
import '../../Provider/TutorialProvider.dart';
import '../../Provider/UserProvider.dart';
import '../Tutorial/TutorialTargets.dart';
import '../Onboarding/LoginScreen.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/MotionReplayScope.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/TossPageRoute.dart';
import 'Widget/AccountActionButtons.dart';
import 'Widget/ReviewReportScreen.dart';
import 'Widget/SettingMenuButtons.dart';
import 'Widget/ThemeChangeButton.dart';
import 'Widget/StreakCard.dart';
import 'Widget/ProfileEditCard.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppToast.dart';
import 'package:ono/Util/AppAnalytics.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Util/NotificationService.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Module/Dialog/ConfirmDialog.dart';

class SettingScreen extends StatefulWidget {
  final TutorialTargets? tutorialTargets;

  const SettingScreen({
    super.key,
    this.tutorialTargets,
  });

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  /// 마이 페이지가 홈의 몇 번째 탭인지. main.dart 의 widgetOptions 순서를 따른다.
  ///
  /// 캐릭터 탭이 셋째 자리에 들어오면서 하나 밀렸다.
  static const int _myPageTabIndex = 4;

  /// 카드가 하나씩 들어오는 간격.
  static const Duration _cardGap = Duration(milliseconds: 80);

  /// 이 탭에 몇 번째로 들어왔는지.
  ///
  /// 홈이 탭 다섯을 IndexedStack 으로 들고 있어서 앱을 켜는 순간 이 화면까지
  /// 함께 만들어진다. 그대로 두면 게이지가 탭을 누르기도 전에 다 차 있으므로,
  /// 들어올 때마다 이 값을 올려 게이지와 카드를 처음부터 다시 재생한다.
  int _visitSequence = 0;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
  }

  /// build 안에서 부른다. setState 를 부르지 않고 값만 갱신하므로 이번 build
  /// 에 그대로 반영된다.
  void _syncVisitSequence(int screenIndex) {
    final isSelected = screenIndex == _myPageTabIndex;
    if (isSelected == _wasSelected) return;
    _wasSelected = isSelected;
    if (isSelected) _visitSequence++;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    _syncVisitSequence(
      Provider.of<ScreenIndexProvider>(context).screenIndex,
    );
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTabletLandscape =
        mediaQuery.size.shortestSide >= 600 && screenWidth > screenHeight;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StandardText(
          text: '${userProvider.userInfoModel?.name ?? '이름 없음'}님의 학습 기록',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              tooltip: '설정',
              icon: Icon(Icons.settings, color: themeProvider.primaryColor),
              onPressed: () {
                Navigator.of(context).push(
                  TossPageRoute(
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
          : MotionReplayScope(
              token: _visitSequence,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: themeProvider.primaryColor,
                child: ListView(
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.only(
                      bottom: screenHeight * 0.01, top: screenHeight * 0.02),
                  children: [
                    // 레벨과 경험치는 캐릭터 탭이 가져갔다. 여기 맨 위에는
                    // 내 사진과 이름이 온다. 마이페이지에서 가장 찾기 쉬워야
                    // 하는 것이고, 예전에는 설정 안쪽에 숨어 있었다.
                    AppearTransition(
                      child: ProfileEditCard(themeProvider: themeProvider),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    AppearTransition(
                      delay: _cardGap,
                      child: ThemeChangeButton(
                        themeProvider: themeProvider,
                        onTap: () {
                          showTossDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ThemeDialog();
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    if (isTabletLandscape)
                      AppearTransition(
                        delay: _cardGap * 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: StreakCard(
                                    key:
                                        widget.tutorialTargets?.calendarCardKey,
                                    themeProvider: themeProvider,
                                    horizontalMarginFactor: 0,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: _buildReviewReportButton(
                                    themeProvider,
                                    horizontalMarginFactor: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      AppearTransition(
                        delay: _cardGap * 2,
                        child: StreakCard(
                          key: widget.tutorialTargets?.calendarCardKey,
                          themeProvider: themeProvider,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      AppearTransition(
                        delay: _cardGap * 3,
                        child: _buildReviewReportButton(themeProvider),
                      ),
                    ],
                    SizedBox(height: screenHeight * 0.01),
                  ],
                ),
              ),
            ),
    );
  }

  /// 로그인하지 않았을 때. 전에는 문구만 있고 로그인으로 가는 길이 없었다.
  /// 글자 크기도 화면 높이에 따라 바뀌어서 고정 크기로 둔다.
  Widget _buildLoginPrompt(ThemeHandler themeProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardText(
            text: '로그인하면 설정을 바꿀 수 있어요',
            fontSize: 15,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              TossPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              elevation: 0,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            child: const StandardText(
              text: '로그인하기',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
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
      key: widget.tutorialTargets?.reportCardKey,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * horizontalMarginFactor,
        vertical: screenHeight * 0.005,
      ),
      child: PressableScale(
        onTap: () {
          Navigator.of(context).push(
            TossPageRoute(
              builder: (context) => const ReviewReportScreen(),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(
            screenHeight * 0.018,
            isTabletLandscape ? screenHeight * 0.030 : screenHeight * 0.018,
            screenHeight * 0.018,
            isTabletLandscape ? screenHeight * 0.024 : screenHeight * 0.014,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
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
                      borderRadius: BorderRadius.circular(AppRadius.medium),
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          // 아래 막대는 고정된 예시라 내 기록처럼 보이지 않게
                          // 밝혀 둔다.
                          StandardText(
                            text: '복습 추이와 약점 분석을 확인해요 · 아래는 예시',
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
              SizedBox(
                  height: isTabletLandscape
                      ? screenHeight * 0.024
                      : screenHeight * 0.014),
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
                                borderRadius:
                                    BorderRadius.circular(AppRadius.small),
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
                                      color: AppColors.textPrimary,
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

class _MyPageSettingsScreen extends StatefulWidget {
  const _MyPageSettingsScreen();

  @override
  State<_MyPageSettingsScreen> createState() => _MyPageSettingsScreenState();
}

class _MyPageSettingsScreenState extends State<_MyPageSettingsScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('MyPageSettingsScreen');
  }

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
                // 프로필 사진과 이름, 테마 변경은 마이페이지 본문으로 나갔다.
                // 여기에는 자주 건드리지 않는 것만 남긴다.
                _buildTutorialReplaySection(
                  context: context,
                  themeProvider: themeProvider,
                  onTap: () {
                    final userId = userProvider.userInfoModel?.userId;
                    if (userId == null) return;
                    final tutorialProvider =
                        Provider.of<TutorialProvider>(context, listen: false);
                    FirebaseAnalytics.instance
                        .logEvent(name: 'tutorial_replay_button_click');
                    Navigator.of(context).pop();
                    screenIndexProvider.setSelectedIndex(0);
                    tutorialProvider.showReplayIntro(userId);
                  },
                ),
                const SizedBox(height: 8),
                SettingMenuButtons(
                  themeProvider: themeProvider,
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
                      // 복습 알림을 끄는 사람이 얼마나 되는지 본다.
                      AppAnalytics.logEvent('notification_setting_change', {
                        'enabled': value,
                      });
                    } catch (_) {
                      if (!context.mounted) return;
                      AppToast.error('알림 설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.');
                      return;
                    }
                    // 켰는데 기기에서 알림을 막아 두었으면 받지 못한다. 전에는
                    // 토글만 켜지고 알림은 오지 않았다.
                    if (!value) return;
                    await NotificationService.instance
                        .requestPermissionIfNeeded(source: 'setting_toggle');
                    if (!await NotificationService.instance
                        .isPermissionDenied()) {
                      return;
                    }
                    AppToast.show(
                      message: '기기 설정에서 OnO 알림이 꺼져 있어요',
                      type: ToastType.info,
                      duration: const Duration(seconds: 5),
                      actionLabel: '설정 열기',
                      onAction: openAppSettings,
                    );
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
                '로그아웃할까요?',
                confirmLabel: '로그아웃',
                // 게스트는 로그아웃하면 데이터가 지워지는데 전에는 괄호 한 줄로만
                // 알렸다.
                '게스트로 이용 중이라면 로그아웃할 때 지금까지 쓴 오답노트와 복습 기록이 모두 지워져요.',
                () async {
                  // 게스트는 로그아웃이 곧 계정 삭제라 서버 요청이 나간다.
                  // 실패하면 로그아웃되지 않은 것이므로 알리고 화면을 두어야
                  // 한다. 예전에는 예외를 아무도 받지 않아 아무 반응 없이
                  // 멈춘 것처럼 보였다.
                  // 서버 요청이 끝날 때까지 아무 표시가 없어 다시 누르게 됐다.
                  LoadingDialog.show(context, '로그아웃하는 중...');
                  try {
                    await userProvider.signOut();
                  } catch (error) {
                    debugPrint('로그아웃 실패: $error');
                    if (context.mounted) LoadingDialog.hide(context);
                    AppToast.error('로그아웃에 실패했어요. 잠시 후 다시 시도해 주세요.');
                    return;
                  }
                  if (context.mounted) LoadingDialog.hide(context);
                  screenIndexProvider.setSelectedIndex(0);

                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    TossPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              onDeleteAccountTap: () => _showConfirmationDialog(
                context,
                '탈퇴할까요?',
                confirmLabel: '탈퇴하기',
                '그동안 작성했던 모든 오답노트 및 개인정보가 삭제돼요. 이 작업은 되돌릴 수 없어요.',
                () async {
                  LoadingDialog.show(context, '탈퇴하는 중...');
                  try {
                    await userProvider.deleteAccount();
                  } catch (error) {
                    debugPrint('회원 탈퇴 실패: $error');
                    if (context.mounted) LoadingDialog.hide(context);
                    AppToast.error('회원 탈퇴에 실패했어요. 잠시 후 다시 시도해 주세요.');
                    return;
                  }
                  if (context.mounted) LoadingDialog.hide(context);
                  screenIndexProvider.setSelectedIndex(0);

                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    TossPageRoute(builder: (context) => const LoginScreen()),
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

Widget _buildTutorialReplaySection({
  required BuildContext context,
  required ThemeHandler themeProvider,
  required VoidCallback onTap,
}) {
  final mediaQuery = MediaQuery.of(context);
  final screenHeight = mediaQuery.size.height;
  final screenWidth = mediaQuery.size.width;

  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.01,
    ),
    padding: EdgeInsets.all(screenHeight * 0.015),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(AppRadius.large),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
    ),
    child: PressableScale(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.008,
          horizontal: screenHeight * 0.01,
        ),
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 20,
              color: themeProvider.primaryColor,
            ),
            SizedBox(width: screenHeight * 0.015),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: '튜토리얼 다시 보기',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(height: 3),
                  StandardText(
                    text: 'OnO 사용법을 처음부터 다시 둘러봐요',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
      ),
    ),
  );
}

/// 로그아웃과 탈퇴를 묻는다. 확정 버튼은 '확인' 대신 [confirmLabel] 로 무엇을
/// 하는지 적는다.
Future<void> _showConfirmationDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm, {
  required String confirmLabel,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: true,
    icon: Icons.warning_amber_rounded,
  );
  if (confirmed) onConfirm();
}
