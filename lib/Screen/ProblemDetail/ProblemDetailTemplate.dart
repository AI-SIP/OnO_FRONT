import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Text/UnderlinedText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'Widget/AnalysisSection.dart';
import 'Widget/ImageSection.dart';
import 'Widget/RepeatSectionV2.dart';

class ProblemDetailTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  const ProblemDetailTemplate({
    required this.problemModel,
    required this.isExpanded,
    required this.onExpansionChanged,
    super.key,
  });

  @override
  State<ProblemDetailTemplate> createState() => _ProblemDetailTemplateState();
}

class _ProblemDetailTemplateState extends State<ProblemDetailTemplate>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
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

    return Column(
      children: [
        // 노트 헤더 (손글씨 탭 바)
        _buildNoteHeader(themeProvider),

        // 탭 내용
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: CustomPaint(
              painter: GridPainter(
                  gridColor: themeProvider.primaryColor, isSpring: true),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProblemTab(themeProvider, isWide),
                  _buildSolutionTab(themeProvider, isWide),
                  _buildReviewHistoryTab(themeProvider, isWide),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteHeader(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
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
      child: TabBar(
        controller: _tabController,
        labelColor: themeProvider.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: [
          Tab(
            child: StandardText(
              text: '문제',
              fontSize: 16,
              fontWeight:
                  _currentTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
              color: _currentTabIndex == 0
                  ? themeProvider.primaryColor
                  : Colors.grey[600]!,
            ),
          ),
          Tab(
            child: StandardText(
              text: '정답',
              fontSize: 16,
              fontWeight:
                  _currentTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
              color: _currentTabIndex == 1
                  ? themeProvider.primaryColor
                  : Colors.grey[600]!,
            ),
          ),
          Tab(
            child: StandardText(
              text: '복습 기록',
              fontSize: 16,
              fontWeight:
                  _currentTabIndex == 2 ? FontWeight.bold : FontWeight.normal,
              color: _currentTabIndex == 2
                  ? themeProvider.primaryColor
                  : Colors.grey[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemTab(ThemeHandler themeProvider, bool isWide) {
    final problemImageCount =
        widget.problemModel.problemImageDataList?.length ?? 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60.0 : 35.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProblemMetaCard(themeProvider),
          const SizedBox(height: 30),

          // 문제 이미지
          _buildProblemSectionHeaderCard(
            '문제 이미지',
            Icons.image_outlined,
            themeProvider,
            trailing: _buildCountChip(problemImageCount, themeProvider),
          ),
          const SizedBox(height: 16),
          _buildProblemImagePanel(
            themeProvider,
            child: buildImageSection(
              context,
              widget.problemModel.problemImageDataList
                      ?.map((m) => m.imageUrl)
                      .toList() ??
                  [],
              '문제 이미지',
              themeProvider,
            ),
          ),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  Widget _buildProblemMetaCard(ThemeHandler themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: themeProvider.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const StandardText(
            text: '푼 날짜',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          const Spacer(),
          UnderlinedText(
            text:
                DateFormat('yyyy년 M월 d일').format(widget.problemModel.solvedAt!),
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(int count, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: StandardText(
        text: '$count장',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildProblemSectionHeaderCard(
      String title, IconData icon, ThemeHandler themeProvider,
      {Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              icon,
              color: themeProvider.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          StandardText(
            text: title,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildProblemImagePanel(ThemeHandler themeProvider,
      {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.14),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSolutionTab(ThemeHandler themeProvider, bool isWide) {
    final answerImageCount =
        widget.problemModel.answerImageDataList?.length ?? 0;

    // 공통 패딩
    final contentPadding = EdgeInsets.symmetric(
      horizontal: isWide ? 60.0 : 35.0,
      vertical: 24.0,
    );

    // AI 분석 결과 위젯
    final aiAnalysisWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AI 분석 결과', Icons.auto_awesome, themeProvider),
        const SizedBox(height: 12),
        buildAnalysisSection(
            context, widget.problemModel.analysis, themeProvider.primaryColor),
      ],
    );

    // 메모 및 해설 이미지 위젯
    final memoAndImageWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.problemModel.memo != null &&
            widget.problemModel.memo!.isNotEmpty) ...[
          _buildSectionTitle('메모', Icons.edit, themeProvider),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: UnderlinedText(
              text: widget.problemModel.memo!,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 25),
        ],

        // 해설 이미지
        _buildSectionTitle(
          '해설 이미지',
          Icons.image_outlined,
          themeProvider,
          trailing: _buildCountChip(answerImageCount, themeProvider),
        ),
        const SizedBox(height: 12),
        _buildProblemImagePanel(
          themeProvider,
          child: buildImageSection(
            context,
            widget.problemModel.answerImageDataList
                    ?.map((m) => m.imageUrl)
                    .toList() ??
                [],
            '해설 이미지',
            themeProvider,
          ),
        ),
      ],
    );

    if (isWide) {
      // 태블릿 가로 (2열) 레이아웃
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0), // 오른쪽 여백
                child: memoAndImageWidget,
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0), // 왼쪽 여백
                child: aiAnalysisWidget,
              ),
            ),
          ],
        ),
      );
    } else {
      // 휴대폰 또는 태블릿 세로 (1열) 레이아웃
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            memoAndImageWidget,
            const SizedBox(height: 24), // 두 섹션 사이 간격
            aiAnalysisWidget,
            const SizedBox(height: 24), // 마지막 섹션 하단 간격
          ],
        ),
      );
    }
  }

  Widget _buildSectionTitle(
      String title, IconData icon, ThemeHandler themeProvider,
      {Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              icon,
              color: themeProvider.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          StandardText(
            text: title,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          const Spacer(),
          if (trailing != null) trailing,
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
