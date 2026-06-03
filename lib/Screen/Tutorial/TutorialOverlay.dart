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
    final maxWidth = mediaQuery.size.width >= 600 ? 420.0 : double.infinity;

    return SafeArea(
      child: Center(
        child: Container(
          width: maxWidth,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StandardText(
                text: 'OnO를 빠르게 둘러볼까요?',
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 12),
              StandardText(
                text: '공책, 오답노트, 복습 세트가 어떻게 연결되는지 짧게 안내해드릴게요.',
                fontSize: 14,
                color: Colors.grey[700]!,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: tutorialProvider.skip,
                    child: StandardText(
                      text: '건너뛰기',
                      fontSize: 14,
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
                    child: const StandardText(
                      text: '시작하기',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
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
    final cardWidth = size.width >= 600 ? 420.0 : size.width - 32;
    final cardLeft = size.width >= 600 ? (size.width - cardWidth) / 2 : 16.0;

    var cardTop = size.height - safeBottom - 250;
    if (rect != null) {
      final below = rect.bottom + 18;
      final above = rect.top - 230;
      if (below + 210 < size.height - safeBottom) {
        cardTop = below;
      } else if (above > safeTop) {
        cardTop = above;
      }
    }
    cardTop =
        cardTop.clamp(safeTop + 12, size.height - safeBottom - 230).toDouble();

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

    return Container(
      key: ValueKey(step.id),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text:
                '${tutorialProvider.currentStepIndex + 1} / ${tutorialSteps.length}',
            fontSize: 12,
            color: themeProvider.primaryColor,
          ),
          const SizedBox(height: 8),
          StandardText(
            text: step.title,
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          StandardText(
            text: step.description,
            fontSize: 14,
            color: Colors.grey[700]!,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: tutorialProvider.skip,
                child: StandardText(
                  text: '건너뛰기',
                  fontSize: 13,
                  color: Colors.grey[700]!,
                ),
              ),
              const Spacer(),
              if (tutorialProvider.currentStepIndex > 0)
                TextButton(
                  onPressed: tutorialProvider.previous,
                  child: StandardText(
                    text: '이전',
                    fontSize: 13,
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
                  text: isLast ? '완료' : '다음',
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
