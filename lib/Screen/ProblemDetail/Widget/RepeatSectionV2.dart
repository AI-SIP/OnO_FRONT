import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Module/Text/StandardLightText.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/AnswerStatus.dart';
import '../../../Model/Problem/ImprovementType.dart';
import '../../../Model/Problem/ProblemModel.dart';
import '../../../Model/Problem/ProblemSolveModel.dart';
import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/HandWriteText.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Service/Api/Problem/ProblemSolveService.dart';
import '../../ProblemSolve/ProblemSolveCompletionScreen.dart';

class RepeatSectionV2 extends StatefulWidget {
  final ProblemModel problem;
  final Color iconColor;
  final bool isWide;

  const RepeatSectionV2({
    super.key,
    required this.problem,
    required this.iconColor,
    required this.isWide,
  });

  @override
  State<RepeatSectionV2> createState() => _RepeatSectionV2State();
}

class _RepeatSectionV2State extends State<RepeatSectionV2>
    with AutomaticKeepAliveClientMixin {
  final problemSolveService = ProblemSolveService();
  late Future<List<ProblemSolveModel>> _problemSolvesFuture;
  final Map<int, bool> _expandedStates = {}; // 각 카드의 펼침 상태 관리

  @override
  void initState() {
    super.initState();
    _problemSolvesFuture = problemSolveService
        .getProblemSolvesByProblemId(widget.problem.problemId);
  }

  @override
  bool get wantKeepAlive => true; // 탭 전환 시에도 상태 유지

  void _toggleExpanded(int solveId, bool newValue) {
    setState(() {
      _expandedStates[solveId] = newValue;
    });
  }

  // 복습 기록 새로고침
  void refresh() {
    setState(() {
      _problemSolvesFuture = problemSolveService
          .getProblemSolvesByProblemId(widget.problem.problemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return FutureBuilder<List<ProblemSolveModel>>(
      future: _problemSolvesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: StandardText(
                text: '복습 기록을 불러올 수 없습니다.',
                fontSize: 16,
                color: Colors.grey[600]!,
              ),
            ),
          );
        }

        final problemSolves = snapshot.data ?? [];

        if (problemSolves.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  StandardText(
                    text: '아직 복습 기록이 없습니다.',
                    fontSize: 16,
                    color: Colors.grey[600]!,
                  ),
                  const SizedBox(height: 8),
                  StandardText(
                    text: '문제를 복습하고 기록을 남겨보세요!',
                    fontSize: 14,
                    color: Colors.grey[500]!,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isWide ? 60.0 : 20.0,
            vertical: 20.0,
          ),
          itemCount: problemSolves.length,
          itemBuilder: (context, index) {
            final solve =
                problemSolves[problemSolves.length - 1 - index]; // 최신순
            final displayIndex = index + 1; // 최신 기록이 1회차
            return _ProblemSolveCard(
              solve: solve,
              index: displayIndex,
              iconColor: widget.iconColor,
              isExpanded: _expandedStates[solve.problemSolveId] ?? false,
              onToggle: (value) => _toggleExpanded(solve.problemSolveId, value),
            );
          },
        );
      },
    );
  }
}

class RepeatSectionV2Wrapper extends StatefulWidget {
  final ProblemModel problem;
  final Color iconColor;
  final bool isWide;

  const RepeatSectionV2Wrapper({
    super.key,
    required this.problem,
    required this.iconColor,
    required this.isWide,
  });

  @override
  State<RepeatSectionV2Wrapper> createState() => _RepeatSectionV2WrapperState();
}

class _RepeatSectionV2WrapperState extends State<RepeatSectionV2Wrapper> {
  final GlobalKey<_RepeatSectionV2State> _repeatSectionKey = GlobalKey<_RepeatSectionV2State>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    return Column(
      children: [
        // 복습 기록 리스트 영역
        Expanded(
          child: RepeatSectionV2(
            key: _repeatSectionKey,
            problem: widget.problem,
            iconColor: widget.iconColor,
            isWide: widget.isWide,
          ),
        ),
        // 버튼 영역
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: widget.isWide ? 60 : 25,
            right: widget.isWide ? 60 : 25,
            top: 10,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 48,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProblemReviewCompletionScreen(
                      problemId: widget.problem.problemId,
                      onRefresh: () {},
                    ),
                  ),
                );

                // 복습 등록 완료 후 새로고침
                if (result == true && mounted) {
                  _repeatSectionKey.currentState?.refresh();
                }
              },
              backgroundColor: themeProvider.primaryColor,
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              label: const StandardText(
                text: '문제 복습하기',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildRepeatSectionV2(
  BuildContext ctx,
  ProblemModel problem,
  Color iconColor,
  bool isWide,
) {
  return RepeatSectionV2Wrapper(
    problem: problem,
    iconColor: iconColor,
    isWide: isWide,
  );
}

class _ProblemSolveCard extends StatelessWidget {
  final ProblemSolveModel solve;
  final int index;
  final Color iconColor;
  final bool isExpanded;
  final Function(bool) onToggle;

  const _ProblemSolveCard({
    required this.solve,
    required this.index,
    required this.iconColor,
    required this.isExpanded,
    required this.onToggle,
  });

  Color _getStatusColor() {
    switch (solve.answerStatus) {
      case AnswerStatus.CORRECT:
        return Colors.green;
      case AnswerStatus.PARTIAL:
        return Colors.orange;
      case AnswerStatus.WRONG:
        return Colors.red;
      case AnswerStatus.UNKNOWN:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (solve.answerStatus) {
      case AnswerStatus.CORRECT:
        return Icons.check_circle;
      case AnswerStatus.PARTIAL:
        return Icons.check_circle_outline;
      case AnswerStatus.WRONG:
        return Icons.cancel;
      case AnswerStatus.UNKNOWN:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final statusColor = _getStatusColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            InkWell(
              onTap: () => onToggle(!isExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16.0)),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14.0)),
                ),
                child: Row(
                  children: [
                    // 상태 아이콘 + 뱃지
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child:
                          Icon(_getStatusIcon(), color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StandardText(
                                text: '$index회차',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: StandardText(
                                  text: solve.answerStatus.displayName,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              StandardText(
                                text: DateFormat('yyyy년 MM월 dd일 HH:mm')
                                    .format(solve.practicedAt),
                                fontSize: 13,
                                color: Colors.grey[600]!,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 확장 아이콘
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ),

            // 상세 내용
            if (isExpanded)
              _buildExpandedContent(context, themeProvider, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, ThemeHandler themeProvider, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 소요 시간
          if (solve.timeSpentSeconds != null)
            _buildInfoRow(
              Icons.timer_outlined,
              '소요 시간',
              '${(solve.timeSpentSeconds! / 60).ceil()}분',
              themeProvider.primaryColor,
            ),
          if (solve.timeSpentSeconds != null) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 개선사항
          if (solve.improvements.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.trending_up,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                const StandardText(
                  text: '개선된 점',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...solve.improvements.map((improvement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StandardLightText(
                        text: improvement.description,
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 회고
          if (solve.reflection != null && solve.reflection!.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.edit_note,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                const StandardText(
                  text: '복습 메모',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: HandWriteText(
                text: solve.reflection!,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),
          ],

          // 풀이 이미지
          if (solve.imageUrls.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Icon(Icons.image_outlined,
                      color: themeProvider.primaryColor, size: 18),
                ),
                const SizedBox(width: 8),
                StandardText(
                  text: '풀이 이미지',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...solve.imageUrls.asMap().entries.map((entry) {
              final imageUrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(imagePath: imageUrl),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: statusColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: DisplayImage(
                        imagePath: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        StandardText(
          text: '$label: ',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        StandardText(
          text: value,
          fontSize: 14,
          color: Colors.black87,
        ),
      ],
    );
  }
}
