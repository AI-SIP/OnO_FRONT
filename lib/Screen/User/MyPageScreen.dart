import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Module/User/ProfileAvatar.dart';
import 'package:ono/Module/Util/UrlLauncher.dart';
import 'package:provider/provider.dart';

import '../../Module/Dialog/ThemeDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/TutorialProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/FileUpload/FileUploadService.dart';
import '../Tutorial/TutorialTargets.dart';
import 'LoginScreen.dart';
import 'Widget/AccountActionButtons.dart';
import 'Widget/ReviewReportScreen.dart';
import 'Widget/SettingMenuButtons.dart';
import 'Widget/ThemeChangeButton.dart';
import 'Widget/StreakCard.dart';
import 'Widget/UserLevelCard.dart';

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
          text: '${userProvider.userInfoModel?.name ?? '이름 없음'}님의 학습 기록',
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
                                key: widget.tutorialTargets?.levelCardKey,
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
                                key: widget.tutorialTargets?.calendarCardKey,
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
                      key: widget.tutorialTargets?.levelCardKey,
                      userInfo: userProvider.userInfoModel,
                      themeProvider: themeProvider,
                      userName: userProvider.userInfoModel?.name ?? '이름 없음',
                    ),
                  ],
                  if (!isTabletLandscape) ...[
                    SizedBox(height: screenHeight * 0.01),
                    StreakCard(
                      key: widget.tutorialTargets?.calendarCardKey,
                      themeProvider: themeProvider,
                    ),
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
      key: widget.tutorialTargets?.reportCardKey,
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

class _MyPageSettingsScreen extends StatefulWidget {
  const _MyPageSettingsScreen();

  @override
  State<_MyPageSettingsScreen> createState() => _MyPageSettingsScreenState();
}

class _MyPageSettingsScreenState extends State<_MyPageSettingsScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingProfileImage = false;

  Future<void> _changeProfileImage() async {
    if (_isUploadingProfileImage) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (pickedFile == null) return;
    if (!_isSupportedProfileImage(pickedFile.path)) {
      _showProfileSnackBar('JPG, PNG, WEBP 이미지만 사용할 수 있어요.');
      return;
    }

    setState(() => _isUploadingProfileImage = true);
    try {
      final imageUrl = await _fileUploadService.uploadImageFile(pickedFile);
      await userProvider.updateUserProfileImageUrl(imageUrl);
      FirebaseAnalytics.instance.logEvent(name: 'profile_image_updated');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: StandardText(
            text: '프로필 이미지 변경에 실패했습니다. 다시 시도해주세요.',
            fontSize: 14,
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingProfileImage = false);
      }
    }
  }

  bool _isSupportedProfileImage(String path) {
    final extension = path.split('.').last.toLowerCase();
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';
  }

  Future<void> _showNameChangeDialog(String currentName) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _NameChangeDialog(
        currentName: currentName,
        themeProvider: themeProvider,
        onSave: (newName) async {
          await userProvider.updateUser(name: newName);
          FirebaseAnalytics.instance.logEvent(name: 'username_updated');
        },
        onError: _showProfileSnackBar,
      ),
    );
  }

  void _showProfileSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: StandardText(
          text: message,
          fontSize: 14,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileSection({
    required BuildContext context,
    required UserProvider userProvider,
    required ThemeHandler themeProvider,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final userInfo = userProvider.userInfoModel;
    final currentName = userInfo?.name ?? '이름 없음';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    imageUrl: userInfo?.profileImageUrl,
                    size: 58,
                    borderColor:
                        themeProvider.primaryColor.withValues(alpha: 0.25),
                    borderWidth: 1.2,
                    backgroundColor:
                        themeProvider.primaryColor.withValues(alpha: 0.06),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isUploadingProfileImage
                            ? null
                            : _changeProfileImage,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _isUploadingProfileImage
                              ? const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: screenHeight * 0.016),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: currentName,
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _showNameChangeDialog(currentName),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor:
                      themeProvider.primaryColor.withValues(alpha: 0.10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: StandardText(
                  text: '이름 변경',
                  fontSize: 13,
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                _buildProfileSection(
                  context: context,
                  userProvider: userProvider,
                  themeProvider: themeProvider,
                ),
                const SizedBox(height: 8),
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

class _NameChangeDialog extends StatefulWidget {
  final String currentName;
  final ThemeHandler themeProvider;
  final Future<void> Function(String newName) onSave;
  final ValueChanged<String> onError;

  const _NameChangeDialog({
    required this.currentName,
    required this.themeProvider,
    required this.onSave,
    required this.onError,
  });

  @override
  State<_NameChangeDialog> createState() => _NameChangeDialogState();
}

class _NameChangeDialogState extends State<_NameChangeDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_isSaving) return;

    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      widget.onError('이름을 입력해주세요.');
      return;
    }
    if (newName.length > 20) {
      widget.onError('이름은 20자 이하로 입력해주세요.');
      return;
    }
    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(newName);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      widget.onError('이름 변경에 실패했습니다. 다시 시도해주세요.');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 380),
      title: const StandardText(
        text: '이름 변경',
        fontSize: 18,
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          enabled: !_isSaving,
          autofocus: true,
          maxLength: 20,
          style: const StandardText(text: '').getTextStyle().copyWith(
                color: Colors.black87,
                fontSize: 14,
              ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '이름을 입력하세요',
            hintStyle: const StandardText(text: '')
                .getTextStyle()
                .copyWith(color: Colors.grey[400], fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: widget.themeProvider.primaryColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
          onSubmitted: (_) => _saveName(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: StandardText(
            text: '취소',
            fontSize: 13,
            color: Colors.grey[700]!,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: _isSaving ? null : _saveName,
          style: TextButton.styleFrom(
            backgroundColor: widget.themeProvider.primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const StandardText(
                  text: '저장',
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
                    color: Colors.black87,
                  ),
                  SizedBox(height: 3),
                  StandardText(
                    text: 'OnO 사용법을 처음부터 다시 둘러봐요',
                    fontSize: 11,
                    color: Colors.grey,
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
