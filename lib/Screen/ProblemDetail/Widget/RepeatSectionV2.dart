import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Module/Text/StandardLightText.dart';
import 'package:ono/Module/Text/UnderlinedText.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/AnswerStatus.dart';
import '../../../Model/Problem/ImprovementType.dart';
import '../../../Model/Problem/ProblemModel.dart';
import '../../../Model/Problem/ProblemSolveModel.dart';
import '../../../Module/Dialog/LoadingDialog.dart';
import '../../../Module/Dialog/SnackBarDialog.dart';
import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Service/Api/Problem/ProblemSolveService.dart';
import '../../ProblemSolve/ProblemSolveRegisterScreen.dart';

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
  int? _selectedSolveId; // 태블릿 상세 패널에 표시할 항목

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

  // 복습 기록 새로고침 (비동기 - 완료될 때까지 대기)
  Future<void> refreshAsync() async {
    final newFuture = problemSolveService
        .getProblemSolvesByProblemId(widget.problem.problemId);

    setState(() {
      _problemSolvesFuture = newFuture;
    });

    // 새로운 데이터 로딩 완료까지 대기
    await newFuture;
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
                  SvgPicture.asset(
                    'assets/Icon/PencilDetail.svg',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const StandardText(
                    text: '아직 복습 기록이 없습니다.',
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  const StandardText(
                    text: '문제를 복습하고 기록을 남겨보세요!',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          );
        }

        final latestFirst =
            List<ProblemSolveModel>.from(problemSolves.reversed);
        if (_selectedSolveId == null ||
            !latestFirst.any((s) => s.problemSolveId == _selectedSolveId)) {
          _selectedSolveId = latestFirst.first.problemSolveId;
        }

        if (widget.isWide) {
          return _buildTabletMasterDetail(context, latestFirst);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 20.0,
          ),
          itemCount: latestFirst.length,
          itemBuilder: (context, index) {
            final solve = latestFirst[index];
            final displayIndex = index + 1; // 최신 기록이 1회차
            return _ProblemSolveCard(
              solve: solve,
              index: displayIndex,
              iconColor: widget.iconColor,
              isExpanded: _expandedStates[solve.problemSolveId] ?? false,
              onToggle: (value) => _toggleExpanded(solve.problemSolveId, value),
              onRefreshAsync: refreshAsync,
            );
          },
        );
      },
    );
  }

  Widget _buildTabletMasterDetail(
      BuildContext context, List<ProblemSolveModel> latestFirst) {
    final selectedIndex = latestFirst
        .indexWhere((solve) => solve.problemSolveId == _selectedSolveId);
    final safeSelectedIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final selectedSolve = latestFirst[safeSelectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12.0),
                itemCount: latestFirst.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final solve = latestFirst[index];
                  return _TabletSolveListItem(
                    solve: solve,
                    index: index + 1,
                    isSelected: solve.problemSolveId == _selectedSolveId,
                    onTap: () {
                      setState(() {
                        _selectedSolveId = solve.problemSolveId;
                      });
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: _ProblemSolveCard(
                solve: selectedSolve,
                index: safeSelectedIndex + 1,
                iconColor: widget.iconColor,
                isExpanded: true,
                onToggle: (_) {},
                onRefreshAsync: refreshAsync,
                showExpandIcon: false,
              ),
            ),
          ),
        ],
      ),
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
  final GlobalKey<_RepeatSectionV2State> _repeatSectionKey =
      GlobalKey<_RepeatSectionV2State>();

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
            bottom: 10,
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
                    builder: (context) => ProblemSolveRegisterScreen(
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
  final Future<void> Function() onRefreshAsync;
  final bool showExpandIcon;

  const _ProblemSolveCard({
    required this.solve,
    required this.index,
    required this.iconColor,
    required this.isExpanded,
    required this.onToggle,
    required this.onRefreshAsync,
    this.showExpandIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final statusColor = _getStatusColor(solve.answerStatus);

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
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
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
                      child: Icon(_getStatusIcon(solve.answerStatus),
                          color: statusColor, size: 22),
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
                    if (showExpandIcon)
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: statusColor,
                      ),
                    if (showExpandIcon) const SizedBox(width: 8),
                    // 메뉴 버튼
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: statusColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _showOptionsDialog(context, themeProvider),
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
            const SizedBox(height: 10),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: UnderlinedText(
                text: solve.reflection!,
                fontSize: 16,
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
                const StandardText(
                  text: '풀이 이미지',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: StandardText(
                    text: '${solve.imageUrls.length}장',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ImageSlider(
              imageUrls: solve.imageUrls,
              statusColor: statusColor,
              primaryColor: themeProvider.primaryColor,
            ),
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

  void _showOptionsDialog(
      BuildContext parentContext, ThemeHandler themeProvider) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: themeProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const StandardText(
                    text: '복습 기록 관리',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 수정 버튼
              // SizedBox(
              //   width: double.infinity,
              //   child: TextButton(
              //     onPressed: () {
              //       Navigator.pop(context);
              //       _handleEdit(context, themeProvider);
              //     },
              //     style: TextButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(
              //           horizontal: 16, vertical: 12),
              //       backgroundColor:
              //           themeProvider.primaryColor.withOpacity(0.1),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(Icons.edit,
              //             color: themeProvider.primaryColor, size: 20),
              //         const SizedBox(width: 8),
              //         StandardText(
              //           text: '수정',
              //           fontSize: 15,
              //           fontWeight: FontWeight.bold,
              //           color: themeProvider.primaryColor,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              // 삭제 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showDeleteConfirmDialog(parentContext, themeProvider);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      StandardText(
                        text: '삭제',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 취소 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const StandardText(
                    text: '취소',
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext parentContext, ThemeHandler themeProvider) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const StandardText(
                    text: '삭제 확인',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 내용
              const StandardText(
                text: '이 복습 기록을 정말 삭제하시겠습니까?',
                fontSize: 15,
                color: Colors.black87,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 액션 버튼
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
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
                        Navigator.pop(dialogContext);
                        _handleDelete(parentContext, themeProvider);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const StandardText(
                        text: '삭제',
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
      ),
    );
  }

  // 수정 핸들러
  void _handleEdit(BuildContext context, ThemeHandler themeProvider) {
    SnackBarDialog.showSnackBar(
      context: context,
      message: '수정 기능은 준비 중입니다.',
      backgroundColor: themeProvider.primaryColor,
    );
  }

  // 삭제 핸들러
  Future<void> _handleDelete(
      BuildContext context, ThemeHandler themeProvider) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    LoadingDialog.show(context, '복습 기록 삭제 중...');

    try {
      final problemSolveService = ProblemSolveService();
      final solveId = solve.problemSolveId; // 삭제할 ID를 미리 저장

      await problemSolveService.deleteProblemSolve(solveId);

      // 먼저 새로고침 후 로딩 닫기
      await onRefreshAsync();

      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }

      if (context.mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습 기록이 삭제되었습니다.',
          backgroundColor: themeProvider.primaryColor,
        );
      }
    } catch (e) {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (context.mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '복습 기록 삭제에 실패했습니다: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }
}

class _TabletSolveListItem extends StatelessWidget {
  final ProblemSolveModel solve;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabletSolveListItem({
    required this.solve,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(solve.answerStatus);
    final borderColor =
        isSelected ? statusColor.withOpacity(0.7) : Colors.grey[300]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? statusColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(_getStatusIcon(solve.answerStatus),
                  color: statusColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StandardText(
                        text: '$index회차',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: StandardText(
                          text: solve.answerStatus.displayName,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StandardText(
                    text: DateFormat('yyyy/MM/dd HH:mm')
                        .format(solve.practicedAt),
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getStatusColor(AnswerStatus status) {
  switch (status) {
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

IconData _getStatusIcon(AnswerStatus status) {
  switch (status) {
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

// 이미지 슬라이더 위젯
class _ImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final Color statusColor;
  final Color primaryColor;

  const _ImageSlider({
    required this.imageUrls,
    required this.statusColor,
    required this.primaryColor,
  });

  @override
  State<_ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<_ImageSlider> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // PageView - 이미지 슬라이더
        Container(
          height: screenHeight * 0.3,
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImage(imagePath: widget.imageUrls[i]),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: DisplayImage(
                    imagePath: widget.imageUrls[i],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          // 도트 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == i ? 12 : 8,
                height: _current == i ? 12 : 8,
                decoration: BoxDecoration(
                  color: _current == i
                      ? widget.primaryColor
                      : widget.primaryColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
