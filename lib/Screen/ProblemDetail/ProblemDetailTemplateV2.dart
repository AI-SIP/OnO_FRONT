import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'Widget/AnalysisSection.dart';
import 'Widget/DateRowWidget.dart';
import 'Widget/ImageSection.dart';
import 'Widget/RepeatSectionV2.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/AppMotion.dart';

class ProblemDetailTemplateV2 extends StatefulWidget {
  final ProblemModel problemModel;

  const ProblemDetailTemplateV2({
    required this.problemModel,
    super.key,
  });

  @override
  State<ProblemDetailTemplateV2> createState() =>
      _ProblemDetailTemplateV2State();
}

class _ProblemDetailTemplateV2State extends State<ProblemDetailTemplateV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // indexIsChanging 은 탭을 눌렀을 때만 참이라, 그것만 보면 손으로 밀어
      // 넘겼을 때 라벨이 이전 탭에 머물러 있었다.
      if (_tabController.index == _currentTabIndex) return;
      AppHaptic.selection();
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Stack(
      children: [
        // 배경 (노트 격자 무늬 + 스프링)
        CustomPaint(
          size: Size.infinite,
          painter: GridPainter(
              gridColor: themeProvider.primaryColor, isSpring: true),
        ),

        Column(
          children: [
            // 노트 헤더 (손글씨 탭 바)
            _buildNoteHeader(themeProvider),

            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _tabContent(0, _buildProblemTab(themeProvider, isWide)),
                  _tabContent(1, _buildSolutionTab(themeProvider, isWide)),
                  _tabContent(2, _buildReviewHistoryTab(themeProvider, isWide)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 탭 사이를 오갈 때 옆으로 밀리기만 하던 것에 옅어짐과 내려앉음을 더한다.
  ///
  /// `TabController.animation` 은 손으로 미는 중에도 계속 값이 바뀌므로,
  /// 탭을 누른 경우와 밀어 넘긴 경우가 같은 모양으로 움직인다.
  Widget _tabContent(int index, Widget child) {
    final animation = _tabController.animation;
    if (animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        // 0 이면 이 탭이 화면 한가운데, 1 이면 완전히 옆으로 비켜난 상태다.
        final distance = (animation.value - index).abs().clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - distance,
          child: Transform.translate(
            offset: Offset(0, 12 * distance),
            child: Transform.scale(
              scale: 1 - 0.02 * distance,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteHeader(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 문제 정보 (날짜)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month,
                      color: themeProvider.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  buildDateRow(widget.problemModel.solvedAt!,
                      themeProvider.primaryColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 탭 바 (손글씨 스타일)
          TabBar(
            controller: _tabController,
            labelColor: themeProvider.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: themeProvider.primaryColor,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              Tab(
                child: _AnimatedTabLabel(
                  text: '문제',
                  selected: _currentTabIndex == 0,
                  fontSize: MobileFontSize.reduced(context, 18),
                  activeColor: themeProvider.primaryColor,
                ),
              ),
              Tab(
                child: _AnimatedTabLabel(
                  text: '정답',
                  selected: _currentTabIndex == 1,
                  fontSize: MobileFontSize.reduced(context, 18),
                  activeColor: themeProvider.primaryColor,
                ),
              ),
              Tab(
                child: _AnimatedTabLabel(
                  text: '복습 기록',
                  selected: _currentTabIndex == 2,
                  fontSize: MobileFontSize.reduced(context, 18),
                  activeColor: themeProvider.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProblemTab(ThemeHandler themeProvider, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60.0 : 35.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildImageSection(
            context,
            widget.problemModel.problemImageDataList
                    ?.map((m) => m.imageUrl)
                    .toList() ??
                [],
            '문제 이미지',
            themeProvider,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSolutionTab(ThemeHandler themeProvider, bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60.0 : 35.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메모
          if (widget.problemModel.memo != null &&
              widget.problemModel.memo!.isNotEmpty)
            _buildMemoCard(themeProvider),
          if (widget.problemModel.memo != null &&
              widget.problemModel.memo!.isNotEmpty)
            const SizedBox(height: 24),

          // 해설 이미지
          buildImageSection(
            context,
            widget.problemModel.answerImageDataList
                    ?.map((m) => m.imageUrl)
                    .toList() ??
                [],
            '해설 이미지',
            themeProvider,
          ),
          const SizedBox(height: 24),

          // AI 분석 결과
          buildAnalysisSection(context, widget.problemModel.analysis,
              themeProvider.primaryColor),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMemoCard(ThemeHandler themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note,
                  color: themeProvider.primaryColor, size: 22),
              const SizedBox(width: 8),
              HandWriteText(
                text: '나의 메모',
                fontSize: 16,
                color: themeProvider.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          HandWriteText(
            text: widget.problemModel.memo!,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHistoryTab(ThemeHandler themeProvider, bool isWide) {
    return buildRepeatSectionV2(
      context,
      widget.problemModel,
      themeProvider.primaryColor,
      isWide,
    );
  }
}

/// 선택된 탭 이름이 한 번 커졌다가 제자리를 잡는다.
///
/// 탭 바 밑줄만 움직이면 어느 쪽을 눌렀는지가 눈에 잘 안 들어와서, 글씨에도
/// 반응을 준다.
class _AnimatedTabLabel extends StatelessWidget {
  final String text;
  final bool selected;
  final double fontSize;
  final Color activeColor;

  const _AnimatedTabLabel({
    required this.text,
    required this.selected,
    required this.fontSize,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selected ? 1.0 : 0.0),
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
      builder: (context, t, _) {
        return Transform.scale(
          scale: 1 + 0.08 * t,
          child: HandWriteText(
            text: text,
            fontSize: fontSize,
            color: Color.lerp(Colors.grey[600]!, activeColor, t)!,
          ),
        );
      },
    );
  }
}
