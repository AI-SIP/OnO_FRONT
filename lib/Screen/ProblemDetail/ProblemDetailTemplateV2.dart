import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/HandWriteText.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'Widget/AnalysisSection.dart';
import 'Widget/DateRowWidget.dart';
import 'Widget/ImageSection.dart';
import 'Widget/RepeatSectionV2.dart';

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
                  _buildProblemTab(themeProvider, isWide),
                  _buildSolutionTab(themeProvider, isWide),
                  _buildReviewHistoryTab(themeProvider, isWide),
                ],
              ),
            ),
          ],
        ),
      ],
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
                  Icon(Icons.calendar_today_outlined,
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
                child: HandWriteText(
                  text: '문제',
                  fontSize: 18,
                  color: _currentTabIndex == 0
                      ? themeProvider.primaryColor
                      : Colors.grey[600]!,
                ),
              ),
              Tab(
                child: HandWriteText(
                  text: '정답',
                  fontSize: 18,
                  color: _currentTabIndex == 1
                      ? themeProvider.primaryColor
                      : Colors.grey[600]!,
                ),
              ),
              Tab(
                child: HandWriteText(
                  text: '복습 기록',
                  fontSize: 18,
                  color: _currentTabIndex == 2
                      ? themeProvider.primaryColor
                      : Colors.grey[600]!,
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
        borderRadius: BorderRadius.circular(16.0),
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
            color: Colors.black87,
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
