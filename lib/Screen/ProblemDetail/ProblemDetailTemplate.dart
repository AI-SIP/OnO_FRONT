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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 60.0 : 35.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 푼 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: themeProvider.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StandardText(
                    text: '푼 날짜',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ],
              ),
              UnderlinedText(
                text: DateFormat('yyyy년 M월 d일')
                    .format(widget.problemModel.solvedAt!),
                fontSize: 15,
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 문제 이미지
          _buildSectionTitle('문제 이미지', Icons.image_outlined, themeProvider),
          const SizedBox(height: 12),
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
          UnderlinedText(
            text: widget.problemModel.memo!,
            fontSize: 18,
          ),
          const SizedBox(height: 25),
        ],

        // 해설 이미지
        _buildSectionTitle('해설 이미지', Icons.image_outlined, themeProvider),
        const SizedBox(height: 12),
        buildImageSection(
          context,
          widget.problemModel.answerImageDataList
                  ?.map((m) => m.imageUrl)
                  .toList() ??
              [],
          '해설 이미지',
          themeProvider,
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
      String title, IconData icon, ThemeHandler themeProvider) {
    return Row(
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
      ],
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
