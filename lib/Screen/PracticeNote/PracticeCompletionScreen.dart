import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import '../User/Widget/FrogMotion.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Emoji/MoodPicker.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/MissionProvider.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../../Module/Motion/SuccessCheck.dart';
import '../../Module/Motion/AnimatedCountText.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppToast.dart';
import '../../Util/AppAnalytics.dart';

class PracticeCompletionScreen extends StatefulWidget {
  final int practiceId;
  final int totalProblems;
  final int practiceRound;

  const PracticeCompletionScreen({
    super.key,
    required this.practiceId,
    required this.totalProblems,
    required this.practiceRound,
  });

  @override
  State<PracticeCompletionScreen> createState() =>
      _PracticeCompletionScreenState();
}

class _PracticeCompletionScreenState extends State<PracticeCompletionScreen> {
  String? _selectedMoodKey;

  /// 완료를 저장하는 중이거나 이미 저장했는지.
  ///
  /// 완료 요청은 보낼 때마다 복습 횟수를 하나씩 올린다. 응답을 기다리는 동안
  /// 확인을 또 누르면 횟수가 그만큼 쌓였다. 저장에 성공하면 화면이 닫힐
  /// 때까지 다시 켜지 않는다.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('PracticeCompletionScreen');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(themeProvider),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: buildCompletionContent(themeProvider),
          ),
          buildConfirmationButton(context, themeProvider, practiceProvider),
        ],
      ),
    );
  }

  AppBar buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: '복습 완료',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    );
  }

  /// 복습을 끝낸 뒤 보는 화면이다.
  ///
  /// 세로 간격을 화면 전체 높이의 비율로 박아 두었더니 여백과 개구리가 화면의
  /// 65% 를 먹어서, 정작 골라 달라고 띄운 기분 고르기가 아래로 밀려 스크롤해야
  /// 보였다. 남은 높이를 재서 그 안에서 간격을 나누도록 바꿨다.
  ///
  /// [SingleChildScrollView] 는 그대로 둔다. 작은 폰이나 글자를 키운 기기에서는
  /// 내용이 남은 높이보다 커지는데, 그때는 [Spacer] 가 0 이 되고 예전처럼
  /// 스크롤된다.
  Widget buildCompletionContent(ThemeHandler themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;

        // 개구리도 남은 높이를 따라간다. 화면 전체 높이로 잡으면 아래 버튼과
        // 앱바가 빠진 만큼 늘 커져서 뒤의 내용을 밀어낸다.
        final frogSize = (available * 0.26).clamp(120.0, 220.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: available),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // 복습을 끝낸 자리다. 캐릭터가 먼저 커지며 나타나고 문구와 기분
                    // 고르기가 차례로 따라온다.
                    AppearTransition(
                      offset: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.86, end: 1.0),
                        duration: AppMotion.slow,
                        curve: AppMotion.emphasized,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // 복습을 끝낸 자리에 서는 것은 내가 꾸민 개구리다.
                              // 배경 파츠는 뺀다. 흰 화면 한가운데에 네모난 배경이
                              // 깔리면 개구리가 아니라 카드가 놓인 것처럼 보인다.
                              //
                              // 나타나면서 한 번 통통 튄다. 입고 있는 치장까지 함께
                              // 움직여야 해서 그림이 아니라 층 전체를 민다.
                              // 확인 표시는 개구리 옆에 그어지는 것이라 같이 튀지
                              // 않게 밖에 둔다.
                              FrogStackMotion(
                                clip: FrogMotion.happyBounce,
                                size: frogSize,
                                tick: 1,
                                child: FrogLayerStack(
                                  layers: context
                                      .watch<CosmeticProvider>()
                                      .layersWithoutBackdrop,
                                  size: frogSize,
                                ),
                              ),
                              // 화면만 바뀌면 끝났다는 느낌이 없어서, 캐릭터 옆에
                              // 확인 표시가 그어지게 했다.
                              SuccessCheck(
                                size: frogSize * 0.3,
                                color: themeProvider.primaryColor,
                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    AppearTransition(
                      delay: AppMotion.stagger * 3,
                      child: StandardText(
                        text: '${widget.practiceRound}회차 복습을 완료했어요',
                        fontSize: MobileFontSize.reduced(context, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppearTransition(
                      delay: AppMotion.stagger * 5,
                      child: AnimatedCountText(
                        value: widget.totalProblems,
                        formatter: (value) => '총 ${value.round()}문제를 풀었어요.',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(flex: 3),
                    AppearTransition(
                      delay: AppMotion.stagger * 7,
                      child: _buildMoodSection(themeProvider),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodSection(ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StandardText(
                text: '이번 복습 어땠나요?',
                fontSize: MobileFontSize.reduced(context, 16),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SelectedMoodChip(
              selectedKey: _selectedMoodKey,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 12),
        MoodPickerRow(
          selectedKey: _selectedMoodKey,
          color: themeProvider.primaryColor,
          onChanged: (key) => setState(() => _selectedMoodKey = key),
        ),
      ],
    );
  }

  Widget buildConfirmationButton(BuildContext context,
      ThemeHandler themeProvider, ProblemPracticeProvider practiceProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting
              ? null
              : () async {
                  // 버튼을 잠그는 것은 다시 그린 뒤부터라, 같은 프레임에 두
                  // 번 눌리면 이 콜백이 두 번 돈다. 복습 횟수가 두 번 오르는
                  // 자리라 눌린 순간에도 확인한다.
                  if (_submitting) return;
                  final navigator = Navigator.of(context);
                  final missionProvider =
                      Provider.of<MissionProvider>(context, listen: false);
                  setState(() => _submitting = true);
                  try {
                    await practiceProvider.addPracticeCount(
                      widget.practiceId,
                      moodEmojiKey: _selectedMoodKey,
                    );
                  } catch (_) {
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    AppToast.error('복습 완료를 저장하지 못했어요.');
                    return;
                  }
                  if (!mounted) return;
                  // 세트를 끝까지 푼 것. 몇 문제짜리를 몇 번째로 끝냈는지와
                  // 기분을 고르는지를 본다.
                  AppAnalytics.logEvent('practice_session_completed', {
                    'problem_count': widget.totalProblems,
                    'round': widget.practiceRound,
                    'mood': _selectedMoodKey ?? 'none',
                  });

                  // 1차에서는 행동 응답에 미션 진행도가 실려 오지 않는다. 세트를
                  // 끝낸 뒤 다시 조회해야 미션이 바로 반영된다.
                  unawaited(missionProvider.fetchMissions());
                  // 2번 pop: PracticeCompletionScreen -> PracticeDetailScreen -> PracticeThumbnailScreen
                  // 두 번째 pop에서 true를 반환하여 썸네일 업데이트 신호 전달
                  if (navigator.canPop()) {
                    navigator.pop(); // PracticeCompletionScreen 닫기
                  }
                  if (navigator.canPop()) {
                    navigator.pop(true); // PracticeDetailScreen 닫으면서 true 반환
                  }
                  AppToast.success('복습을 완료했습니다!');
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            // 저장하는 동안에도 흐려지지 않게 같은 색을 쓴다. 대신 글자
            // 자리에 도는 표시를 둔다.
            disabledBackgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            elevation: 0,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const StandardText(
                  text: "확인",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
