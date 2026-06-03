// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/TutorialProvider.dart';
import 'TutorialStep.dart';
import 'TutorialTargets.dart';

class TutorialOverlay extends StatefulWidget {
  final TutorialTargets targets;

  const TutorialOverlay({
    super.key,
    required this.targets,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  static const Duration _motionDuration = Duration(milliseconds: 280);
  static const Curve _motionCurve = Curves.easeOutCubic;
  static const String _guideFrogAsset = 'assets/FrogCharacter/FROG_LEVEL15.png';
  static const double _speechBorderWidth = 1.0;

  Rect? _targetRect;
  String? _lastStepId;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_updateTargetRect());
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
    final maxHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        32;

    return SafeArea(
      child: Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFrogSpeech(
                    themeProvider: themeProvider,
                    frogSize: frogSize,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardText(
                          text: 'OnO를 빠르게 둘러볼까요?',
                          fontSize: titleSize,
                          color: Colors.black87,
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
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: tutorialProvider.skip,
                        child: StandardText(
                          text: '건너뛰기',
                          fontSize: buttonSize,
                          color: Colors.grey[700]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: tutorialProvider.start,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
    final maxHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        32;

    return SafeArea(
      child: Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFrogSpeech(
                    themeProvider: themeProvider,
                    frogSize: frogSize,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StandardText(
                          text: '좋아요, 이제 OnO와 함께 시작해봐요!',
                          fontSize: titleSize,
                          color: Colors.black87,
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
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      TextButton(
                        onPressed: tutorialProvider.previous,
                        child: StandardText(
                          text: '이전',
                          fontSize: buttonSize,
                          color: Colors.grey[700]!,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: tutorialProvider.complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                ],
              ),
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
    final safeBottom = mediaQuery.padding.bottom;
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final cardWidth = isTablet ? 560.0 : size.width - 32;
    final cardLeft = size.width >= 600 ? (size.width - cardWidth) / 2 : 16.0;
    final cardMaxHeight = size.height - safeTop - safeBottom - 32;
    final estimatedCardHeight = isTablet ? 310.0 : 230.0;

    var cardTop = size.height - safeBottom - estimatedCardHeight - 20;
    if (rect != null) {
      final below = rect.bottom + 18;
      final above = rect.top - estimatedCardHeight;
      if (below + estimatedCardHeight < size.height - safeBottom) {
        cardTop = below;
      } else if (above > safeTop) {
        cardTop = above;
      }
    }
    final minCardTop = safeTop + 12;
    final maxCardTop = size.height - safeBottom - estimatedCardHeight;
    final clampedMaxCardTop = maxCardTop < minCardTop ? minCardTop : maxCardTop;
    cardTop = cardTop.clamp(minCardTop, clampedMaxCardTop).toDouble();

    return Stack(
      children: [
        if (rect != null)
          AnimatedPositioned(
            duration: _motionDuration,
            curve: _motionCurve,
            left: (rect.left - 8).clamp(8.0, size.width - 24).toDouble(),
            top: (rect.top - 8).clamp(safeTop + 8, size.height - 24).toDouble(),
            width: (rect.width + 16).clamp(24.0, size.width - 16).toDouble(),
            height: (rect.height + 16)
                .clamp(24.0, size.height - safeTop - 16)
                .toDouble(),
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: _motionDuration,
                curve: _motionCurve,
                opacity: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: themeProvider.primaryColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            themeProvider.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: _motionDuration,
          curve: _motionCurve,
          left: cardLeft,
          top: cardTop,
          width: cardWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: cardMaxHeight),
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFrogSpeech(
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
                const SizedBox(height: 12),
                StandardText(
                  text: step.title,
                  fontSize: titleSize,
                  color: Colors.black87,
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
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: tutorialProvider.skip,
                child: StandardText(
                  text: '건너뛰기',
                  fontSize: buttonSize,
                  color: Colors.grey[700]!,
                ),
              ),
              const Spacer(),
              if (tutorialProvider.currentStepIndex > 0)
                TextButton(
                  onPressed: tutorialProvider.previous,
                  child: StandardText(
                    text: '이전',
                    fontSize: buttonSize,
                    color: Colors.grey[700]!,
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: tutorialProvider.next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: StandardText(
                  text: '다음',
                  fontSize: buttonSize,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        Image.asset(
          _guideFrogAsset,
          width: frogSize,
          height: frogSize,
          fit: BoxFit.contain,
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
                  borderRadius: BorderRadius.circular(18),
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
