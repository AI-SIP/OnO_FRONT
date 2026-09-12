// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/TutorialProvider.dart';
import '../../Provider/CosmeticProvider.dart';
import '../User/Widget/FrogCharacter.dart';
import 'TutorialStep.dart';
import 'TutorialTargets.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/StepProgressBar.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialTargets targets;

  const TutorialOverlay({
    super.key,
    required this.targets,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  // 다른 화면과 같은 값을 쓴다. 튜토리얼만 따로 놀지 않게 한다.
  static const Duration _motionDuration = AppMotion.normal;
  static const Curve _motionCurve = AppMotion.enter;
  static const double _speechBorderWidth = 1.0;

  /// 안내 카드가 스크롤 없이 들어가려면 대략 이만큼은 있어야 한다.
  /// 글자 크기 1배에서 가장 긴 단계를 실제로 재서(폰 320dp 392, 태블릿 341)
  /// 조금 올려 잡은 값이다. 글자 배율을 곱해서 쓴다.
  ///
  /// 카드를 대상 위에 둘지 아래에 둘지 고르는 데만 쓰는 값이다. 카드 높이를
  /// 이걸로 정하지는 않는다. 고른 자리에서 쓸 수 있는 높이는 언제나 그
  /// 자리에 실제로 남은 만큼이라, 이 값이 실제와 어긋나도 자리를 덜 좋게
  /// 고르는 것에서 끝나고 카드가 잘리지는 않는다.
  static const double _phoneCardRoom = 400.0;
  static const double _tabletCardRoom = 350.0;

  /// 이만큼도 안 되는 자리라면 대상을 비켜 줘도 카드가 너무 좁아 보람이 없다.
  static const double _usableCardRoom = 240.0;

  /// 이보다 작은 대상은 화면 아래에 앉은 카드에 통째로 가려진다.
  /// + 추가 버튼이 56dp 다.
  static const double _smallTargetHeight = 160.0;

  /// 계산 결과가 0 이하로 내려가도 카드에 이만큼은 준다. 안에서
  /// 스크롤되더라도 카드가 아예 안 그려지는 것보다는 낫다.
  static const double _minCardHeight = 120.0;

  /// 강조 테두리를 알아볼 수 있는 최소 높이.
  static const double _minHighlightHeight = 24.0;

  Rect? _targetRect;
  String? _lastStepId;

  /// 단계가 바뀔 때 테두리를 한 번 두껍게 했다 되돌린다.
  ///
  /// 복습 세트와 스터디룸처럼 이어지는 두 단계가 둘 다 화면 전체를 가리키면
  /// 테두리 위치가 거의 같아서 화면이 넘어간 줄 모른다. 한 번 반짝이면
  /// 다음으로 넘어왔다는 것이 눈에 들어온다.
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStep();
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStep();
  }

  void _syncStep() {
    final tutorialProvider =
        Provider.of<TutorialProvider>(context, listen: false);
    if (!tutorialProvider.isRunning) return;

    final step = tutorialProvider.currentStep;
    if (_lastStepId == step.id) {
      unawaited(_updateTargetRect());
      return;
    }

    _lastStepId = step.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _updateTargetRect();
      if (!mounted) return;
      _pulseController.forward(from: 0.0);
    });
  }

  Future<void> _updateTargetRect() async {
    final tutorialProvider =
        Provider.of<TutorialProvider>(context, listen: false);
    if (!tutorialProvider.isRunning) return;

    final targetKey =
        tutorialProvider.currentStep.targetType.resolve(widget.targets);

    for (var attempt = 0; attempt < 4; attempt++) {
      final targetContext = targetKey.currentContext;
      if (targetContext != null) {
        unawaited(Scrollable.ensureVisible(
          targetContext,
          duration: _motionDuration,
          curve: _motionCurve,
          alignment: 0.35,
        ));
        await Future<void>.delayed(_motionDuration);
        if (!mounted) return;
        final updatedTargetContext = targetKey.currentContext;
        final renderObject = updatedTargetContext?.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          final offset = renderObject.localToGlobal(Offset.zero);
          setState(() {
            _targetRect = offset & renderObject.size;
          });
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    if (mounted) {
      setState(() {
        _targetRect = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialProvider = Provider.of<TutorialProvider>(context);
    if (!tutorialProvider.isVisible) {
      _lastStepId = null;
      return const SizedBox.shrink();
    }

    if (tutorialProvider.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncStep());
    }

    final themeProvider = Provider.of<ThemeHandler>(context);

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.58)),
            if (tutorialProvider.isIntro)
              _buildIntroCard(tutorialProvider, themeProvider)
            else if (tutorialProvider.isOutro)
              _buildOutroCard(tutorialProvider, themeProvider)
            else
              _buildStepOverlay(tutorialProvider, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(
    TutorialProvider tutorialProvider,
    ThemeHandler themeProvider,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final maxWidth = isTablet ? 560.0 : double.infinity;
    final horizontalMargin = isTablet ? 32.0 : 24.0;
    final cardPadding = isTablet ? 28.0 : 22.0;
    final titleSize = isTablet ? 18.0 : 14.0;
    final bodySize = isTablet ? 14.0 : 12.0;
    final buttonSize = isTablet ? 14.0 : 13.0;
    final frogSize = isTablet ? 116.0 : 86.0;
    final safeTop = mediaQuery.padding.top;
    // 하단은 padding 만 봐서는 모자란다. 제스처 내비게이션 기기는 padding 이
    // 작게 잡히는 대신 화면 아래에서 쓸어 올리는 영역이 넓어서, SafeArea 만
    // 믿으면 버튼이 그 영역에 걸린다.
    final bottomObstruction = _maxBottomInset(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
      mediaQuery.systemGestureInsets.bottom,
    );
    final maxHeight = mediaQuery.size.height - safeTop - bottomObstruction - 32;

    return Padding(
      padding: EdgeInsets.only(top: safeTop, bottom: bottomObstruction),
      child: Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 넘치는 것은 설명 쪽이다. 카드 전체를 스크롤시키면 글자를
                // 키운 기기에서 버튼 줄이 스크롤 아래로 밀려 보이지 않는다.
                // 설명만 스크롤시키고 버튼은 카드 아래에 붙여 둔다.
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildFrogSpeech(
                      themeProvider: themeProvider,
                      frogSize: frogSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StandardText(
                            text: 'OnO를 빠르게 둘러볼까요?',
                            fontSize: titleSize,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 14),
                          StandardText(
                            text: '공책, 오답노트, 복습 세트가\n어떻게 연결되는지 짧게 안내해드릴게요.',
                            fontSize: bodySize,
                            color: Colors.grey[700]!,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'PretendardBold',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // 글자를 키운 기기에서는 두 버튼이 한 줄에 다 들어가지 않아
                // 오른쪽으로 넘쳤다. 넘치면 아랫줄로 내린다.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: tutorialProvider.skip,
                      child: StandardText(
                        text: '건너뛰기',
                        fontSize: buttonSize,
                        color: Colors.grey[700]!,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: tutorialProvider.start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: StandardText(
                        text: '시작하기',
                        fontSize: buttonSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutroCard(
    TutorialProvider tutorialProvider,
    ThemeHandler themeProvider,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final maxWidth = isTablet ? 560.0 : double.infinity;
    final horizontalMargin = isTablet ? 32.0 : 24.0;
    final cardPadding = isTablet ? 28.0 : 22.0;
    final frogSize = isTablet ? 104.0 : 76.0;
    final titleSize = isTablet ? 18.0 : 14.0;
    final bodySize = isTablet ? 14.0 : 12.0;
    final buttonSize = isTablet ? 14.0 : 13.0;
    final safeTop = mediaQuery.padding.top;
    // 하단은 padding 만 봐서는 모자란다. 제스처 내비게이션 기기는 padding 이
    // 작게 잡히는 대신 화면 아래에서 쓸어 올리는 영역이 넓어서, SafeArea 만
    // 믿으면 버튼이 그 영역에 걸린다.
    final bottomObstruction = _maxBottomInset(
      mediaQuery.padding.bottom,
      mediaQuery.viewPadding.bottom,
      mediaQuery.systemGestureInsets.bottom,
    );
    final maxHeight = mediaQuery.size.height - safeTop - bottomObstruction - 32;

    return Padding(
      padding: EdgeInsets.only(top: safeTop, bottom: bottomObstruction),
      child: Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 넘치는 것은 설명 쪽이다. 카드 전체를 스크롤시키면 글자를
                // 키운 기기에서 버튼 줄이 스크롤 아래로 밀려 보이지 않는다.
                // 설명만 스크롤시키고 버튼은 카드 아래에 붙여 둔다.
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildFrogSpeech(
                      themeProvider: themeProvider,
                      frogSize: frogSize,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StandardText(
                            text: '좋아요, 이제 OnO와 함께 시작해봐요!',
                            fontSize: titleSize,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 14),
                          StandardText(
                            text:
                                '공책에 오답을 모으고, 복습 세트로 다시 복습하면서 100점을 향해 한 걸음씩 나아가요!',
                            fontSize: bodySize,
                            color: Colors.grey[700]!,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'PretendardBold',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    TextButton(
                      onPressed: tutorialProvider.previous,
                      style: TextButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: StandardText(
                        text: '이전',
                        fontSize: buttonSize,
                        color: Colors.grey[700]!,
                      ),
                    ),
                    // 스텝 카드와 같은 방식이다. 남는 자리를 오른쪽 묶음이
                    // 가져가고, 글자를 키워 한 줄에 안 들어가면 아랫줄로 내린다.
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: tutorialProvider.complete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.small),
                              ),
                            ),
                            child: StandardText(
                              text: '완료',
                              fontSize: buttonSize,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOverlay(
    TutorialProvider tutorialProvider,
    ThemeHandler themeProvider,
  ) {
    final rect = _targetRect;
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final safeTop = mediaQuery.padding.top;
    final systemBottomInset = _maxBottomInset(mediaQuery.padding.bottom,
        mediaQuery.viewPadding.bottom, mediaQuery.systemGestureInsets.bottom);
    final bottomObstruction = systemBottomInset > mediaQuery.viewInsets.bottom
        ? systemBottomInset
        : mediaQuery.viewInsets.bottom;
    final reservedBottom =
        bottomObstruction + kBottomNavigationBarHeight + 12.0;
    final availableBottom = size.height - reservedBottom;
    final minCardTop = safeTop + 12;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final cardWidth = isTablet ? 560.0 : size.width - 32;
    final cardLeft = size.width >= 600 ? (size.width - cardWidth) / 2 : 16.0;
    // 글자 크기를 키운 기기에서는 제목과 설명이 여러 줄로 늘어나 카드가
    // 그만큼 커진다. 삼성 기기는 기본 글자도 크고 접근성에서 더 키우는
    // 사용자도 많다. 카드를 대상 위와 아래 중 어디에 둘지 고를 때 이걸
    // 같이 본다.
    final textScale = mediaQuery.textScaler.scale(1.0);
    final slot = _cardSlot(
      targetRect: rect,
      minCardTop: minCardTop,
      availableBottom: availableBottom,
      requiredRoom: (isTablet ? _tabletCardRoom : _phoneCardRoom) * textScale,
    );
    final highlight = rect == null
        ? null
        : _highlightBand(
            targetRect: rect,
            screen: size,
            // 강조 사각형은 위로는 상태 바 아래에서, 아래로는 하단 탭 바
            // 위에서 끊는다. 4/7 `레벨과 성장` 의 대상 키가 화면 전체를
            // 차지하는 무대(_CharacterStage)에 붙어 있어서, 끊지 않으면
            // 강조 테두리가 탭 바까지 함께 감쌌다. 탭 바는 어느 단계에서도
            // 설명하는 대상이 아니다.
            top: safeTop + 8,
            bottomLimit: size.height -
                bottomObstruction -
                kBottomNavigationBarHeight -
                8,
          );

    return Stack(
      children: [
        if (highlight != null)
          AnimatedPositioned(
            duration: _motionDuration,
            curve: _motionCurve,
            left: highlight.left,
            top: highlight.top,
            width: highlight.width,
            height: highlight.height,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: _motionDuration,
                curve: _motionCurve,
                opacity: 1,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    // 0 에서 1 로 가는 동안 두껍고 진했다가 제자리로 돌아온다.
                    final t = Curves.easeOut.transform(_pulseController.value);
                    final emphasis = 1.0 - t;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(
                          color: themeProvider.primaryColor,
                          width: 3 + 3 * emphasis,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.primaryColor
                                .withValues(alpha: 0.35 + 0.35 * emphasis),
                            blurRadius: 18 + 14 * emphasis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: _motionDuration,
          curve: _motionCurve,
          left: cardLeft,
          // 위 변이 아니라 아래 변을 잡는다. 카드는 제 내용만큼 위로 자라고,
          // 고른 자리에 실제로 남은 높이로만 묶인다. 그래서 `이전`·`다음` 이
          // 하단 내비게이션에 깔리는 일도, 남은 자리를 못 쓰고 설명이
          // 잘리는 일도 없다.
          bottom: size.height - slot.bottom,
          width: cardWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: slot.maxHeight),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildStepCard(tutorialProvider, themeProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(
    TutorialProvider tutorialProvider,
    ThemeHandler themeProvider,
  ) {
    final step = tutorialProvider.currentStep;
    final isLast =
        tutorialProvider.currentStepIndex == tutorialSteps.length - 1;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final cardPadding = isTablet
        ? const EdgeInsets.fromLTRB(22, 22, 22, 18)
        : const EdgeInsets.fromLTRB(16, 16, 16, 14);
    final frogSize = isTablet ? 104.0 : 76.0;
    final progressSize = isTablet ? 11.0 : 10.0;
    final titleSize = isTablet ? 18.0 : 14.0;
    final bodySize = isTablet ? 14.0 : 12.0;
    final buttonSize = isTablet ? 14.0 : 12.0;

    return Container(
      key: ValueKey(step.id),
      padding: cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 넘치는 것은 설명 쪽이다. 카드 전체를 스크롤시키면 글자가 길 때
          // 버튼까지 화면 밖으로 밀려나므로, 설명만 스크롤시키고 버튼 줄은
          // 카드 아래에 붙여 둔다. 그래야 어떤 글자 크기에서도 `다음` 을
          // 누를 수 있다.
          Flexible(
            child: SingleChildScrollView(
              child: _buildFrogSpeech(
                themeProvider: themeProvider,
                frogSize: frogSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text:
                          '${tutorialProvider.currentStepIndex + 1} / ${tutorialSteps.length}',
                      fontSize: progressSize,
                      color: themeProvider.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    // 숫자만으로는 얼마나 남았는지 잘 안 들어와서 막대를 함께 둔다.
                    StepProgressBar(
                      currentStep: tutorialProvider.currentStepIndex + 1,
                      totalSteps: tutorialSteps.length,
                      color: themeProvider.primaryColor,
                      backgroundColor:
                          themeProvider.primaryColor.withValues(alpha: 0.15),
                      height: 3,
                    ),
                    const SizedBox(height: 12),
                    StandardText(
                      text: step.title,
                      fontSize: titleSize,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 8),
                    StandardText(
                      text: step.description,
                      fontSize: bodySize,
                      color: Colors.grey[700]!,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'PretendardBold',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: tutorialProvider.skip,
                // Material 버튼은 기본으로 48px 터치 영역을 확보하느라
                // 좌우에 여백이 붙는다. 그대로 두면 위 설명 텍스트와
                // 시작점, 끝점이 어긋난다.
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: StandardText(
                  text: '건너뛰기',
                  fontSize: buttonSize,
                  color: Colors.grey[700]!,
                ),
              ),
              // 남는 자리를 오른쪽 묶음이 다 가져가야 카드 오른쪽 끝에 붙는다.
              // 양쪽을 Flexible 로 두면 남는 폭을 절반씩 갈라 가져서, 오른쪽
              // 버튼과 카드 사이에 빈 자리가 남았다.
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (tutorialProvider.currentStepIndex > 0)
                      TextButton(
                        onPressed: tutorialProvider.previous,
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: StandardText(
                          text: '이전',
                          fontSize: buttonSize,
                          color: Colors.grey[700]!,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: tutorialProvider.next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      child: StandardText(
                        text: isLast ? '마무리' : '다음',
                        fontSize: buttonSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 안내 카드가 놓일 자리다. 카드 아래 변의 y 좌표와, 그 자리에서 위로
  /// 쓸 수 있는 높이를 준다.
  ///
  /// 카드는 아래 변을 고정하고 제 내용만큼 위로 자란다. 그래서 자리를 잡는
  /// 데 카드 높이를 미리 알 필요가 없다. 예전에는 위 변을 정해야 해서
  /// 높이를 짐작했고(폰 230, 태블릿 310에 글자 배율), 짐작이 실제보다 작으면
  /// 카드가 그만큼 바닥 쪽으로 내려앉아 위로 남아 있던 자리를 스스로
  /// 버렸다. 설명이 긴 단계에서 카드 안에 스크롤이 생긴 것이 이 때문이다.
  ///
  /// 고르는 순서는 이렇다. 먼저 대상 위와 아래 중 카드가 다 들어가는
  /// ([requiredRoom] 만큼 남는) 쪽을 쓰고, 둘 다 들어가면 넓은 쪽을 쓴다.
  /// 어느 쪽을 골라도 카드는 대상을 덮지 않는다.
  ///
  /// 둘 다 모자라면 대상을 덮더라도 화면 아래에 붙이고 쓸 수 있는 높이를 다
  /// 쓴다. 목록처럼 대상이 화면을 거의 다 차지하는 단계가 여기로 온다.
  /// 카드가 그 일부만 덮으니 설명하는 것은 계속 보이고, 대신 설명이 다
  /// 보인다.
  ///
  /// 대상이 작으면 이야기가 다르다. 2/7 `오답노트 작성 시작` 의 + 추가
  /// 버튼은 56dp 짜리라 화면 아래에 앉은 카드에 통째로 가려진다. 그런
  /// 단계는 카드가 좁아져 안에서 스크롤이 생겨도 비켜 주는 편이 낫다.
  /// 설명하는 것이 안 보이면 안내가 아니다.
  ({double bottom, double maxHeight}) _cardSlot({
    required Rect? targetRect,
    required double minCardTop,
    required double availableBottom,
    required double requiredRoom,
  }) {
    // 대상과 카드 사이 간격, 그리고 카드와 하단 사이 간격이다.
    const gap = 18.0;
    const bottomPad = 8.0;

    final defaultBottom = availableBottom - bottomPad;
    final fullRoom = defaultBottom - minCardTop;

    if (targetRect != null) {
      final aboveBottom = targetRect.top - gap;
      final above = (
        bottom: aboveBottom,
        room: aboveBottom - minCardTop,
      );
      // 아래를 고르면 카드는 기본 자리인 화면 아래에 그대로 두고 높이만
      // 묶는다. 그러면 카드 위 변이 대상 아래로 내려온다.
      final below = (
        bottom: defaultBottom,
        room: defaultBottom - (targetRect.bottom + gap),
      );
      // 넓은 쪽을 먼저 본다.
      final ordered =
          above.room >= below.room ? [above, below] : [below, above];

      for (final slot in ordered) {
        if (slot.room >= requiredRoom && slot.bottom <= defaultBottom) {
          return (bottom: slot.bottom, maxHeight: slot.room);
        }
      }
      if (targetRect.height <= _smallTargetHeight) {
        for (final slot in ordered) {
          if (slot.room >= _usableCardRoom && slot.bottom <= defaultBottom) {
            return (bottom: slot.bottom, maxHeight: slot.room);
          }
        }
      }
    }

    return (
      bottom: defaultBottom,
      maxHeight: fullRoom < _minCardHeight ? _minCardHeight : fullRoom,
    );
  }

  /// 대상을 감쌀 강조 사각형이다.
  ///
  /// [top] 과 [bottomLimit] 사이로 자른다. 대상이 화면을 통째로 차지해도
  /// 강조가 상태 바나 하단 탭 바까지 넘어가지 않게 하는 것이 이 자르기다.
  Rect _highlightBand({
    required Rect targetRect,
    required Size screen,
    required double top,
    required double bottomLimit,
  }) {
    var bandTop = targetRect.top - 8;
    var bandBottom = targetRect.bottom + 8;
    if (bandTop < top) bandTop = top;
    if (bandBottom > bottomLimit) bandBottom = bottomLimit;
    if (bandBottom - bandTop < _minHighlightHeight) {
      bandTop = bandBottom - _minHighlightHeight;
      if (bandTop < top) bandTop = top;
    }
    final height = bandBottom - bandTop;

    return Rect.fromLTWH(
      (targetRect.left - 8).clamp(8.0, screen.width - 24).toDouble(),
      bandTop,
      (targetRect.width + 16).clamp(24.0, screen.width - 16).toDouble(),
      height < _minHighlightHeight ? _minHighlightHeight : height,
    );
  }

  double _maxBottomInset(double padding, double viewPadding, double gesture) {
    if (viewPadding > padding && viewPadding > gesture) {
      return viewPadding;
    }
    if (gesture > padding) {
      return gesture;
    }
    return padding;
  }

  Widget _buildFrogSpeech({
    required ThemeHandler themeProvider,
    required Widget child,
    double frogSize = 86,
  }) {
    final bubbleColor = Color.alphaBlend(
      themeProvider.primaryColor.withValues(alpha: 0.08),
      Colors.white,
    );
    final bubbleBorderColor =
        themeProvider.primaryColor.withValues(alpha: 0.20);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 안내를 하는 것도 내가 꾸민 개구리다. 앱을 처음 열었을 때부터
        // 같은 개구리가 따라다녀야 이 앱의 마스코트로 읽힌다. 배경 파츠는
        // 뺀다. 말풍선 옆에 네모난 배경이 깔리면 개구리가 아니라 카드가
        // 놓인 것처럼 보인다.
        FrogLayerStack(
          layers: context.watch<CosmeticProvider>().layersWithoutBackdrop,
          size: frogSize,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: bubbleBorderColor,
                    width: _speechBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: child,
              ),
              Positioned(
                left: -21,
                top: 26,
                child: CustomPaint(
                  size: const Size(23, 24),
                  painter: _SpeechTailPainter(
                    color: bubbleColor,
                    borderColor: bubbleBorderColor,
                    borderWidth: _speechBorderWidth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const _SpeechTailPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final joinX = size.width;
    final borderEndX = size.width - 1;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(joinX, 0)
      ..lineTo(joinX, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final borderPath = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(borderEndX, borderWidth / 2)
      ..moveTo(0, size.height / 2)
      ..lineTo(borderEndX, size.height - borderWidth / 2);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}
