import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/StudyRoom/SharedProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';
import '../ProblemDetail/Widget/ImageGallerySection.dart';
import 'Widget/FeedReactionBar.dart';
import 'Widget/SharedProblemCommentsSection.dart';

class SharedProblemDetailScreen extends StatelessWidget {
  final SharedProblemModel problem;

  const SharedProblemDetailScreen({super.key, required this.problem});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SharedProblemModel problem,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '공유 취소',
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StandardText(
                  text: '이 문제 공유를 취소할까요?',
                  fontSize: 14,
                  color: Colors.grey[700]!,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const StandardText(
                          text: '닫기',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소하기',
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
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await provider.deleteSharedProblem(problem.sharedProblemId);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) AppSnackBar.showError('공유 취소에 실패했습니다');
    }
  }

  void _showProblemActions(
    BuildContext context,
    SharedProblemModel problem,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
  ) {
    final primary = themeProvider.primaryColor;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '공유 문제 관리',
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _confirmDelete(context, problem, provider, themeProvider);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.16),
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        StandardText(
                          text: '삭제',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[50],
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: const StandardText(
                      text: '닫기',
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context);
    final primary = themeProvider.primaryColor;
    final p = provider.sharedProblems
        .where((item) => item.sharedProblemId == problem.sharedProblemId)
        .firstOrNull;
    final currentProblem = p ?? problem;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: StandardText(
          text: currentProblem.reference,
          fontSize: 17,
          color: primary,
          fontWeight: FontWeight.w700,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _buildDetailHeader(
              context, currentProblem, primary, provider, themeProvider),
          const SizedBox(height: 14),
          _buildProblemDetail(currentProblem, primary, themeProvider),
          if (currentProblem.comment != null &&
              currentProblem.comment!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildOwnerComment(currentProblem),
          ],
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FeedReactionBar(
              reactions: currentProblem.reactions,
              themeProvider: themeProvider,
              onToggle: (emoji) => provider.toggleSharedProblemReaction(
                currentProblem.sharedProblemId,
                emoji,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SharedProblemCommentsSection(
            sharedProblemId: currentProblem.sharedProblemId,
            initialCommentCount: currentProblem.commentCount,
            themeProvider: themeProvider,
            initiallyExpanded: true,
            showToggle: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(
    BuildContext context,
    SharedProblemModel problem,
    Color primary,
    StudyRoomProvider provider,
    ThemeHandler themeProvider,
  ) {
    final isOwner = provider.currentUserId == problem.sharedByUserId;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Icon(Icons.person_outline, size: 19, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StandardText(
                text: problem.sharedByName,
                fontSize: 14,
                color: Colors.black87,
              ),
              StandardText(
                text: _timeAgo(problem.sharedAt),
                fontSize: 12,
                color: Colors.grey[500]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
            ],
          ),
        ),
        if (isOwner)
          IconButton(
            icon: Icon(Icons.more_vert, size: 22, color: Colors.grey[500]),
            tooltip: '공유 문제 메뉴',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            onPressed: () => _showProblemActions(
              context,
              problem,
              provider,
              themeProvider,
            ),
          ),
      ],
    );
  }

  Widget _buildProblemDetail(
    SharedProblemModel problem,
    Color primary,
    ThemeHandler themeProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem.problemImageUrls.isNotEmpty)
            ImageGallerySection(
              imageUrls: problem.problemImageUrls,
              label: problem.reference,
              color: primary,
              themeProvider: themeProvider,
            )
          else
            _detailPlaceholder(primary),
        ],
      ),
    );
  }

  Widget _buildOwnerComment(SharedProblemModel problem) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 2),
      child: StandardText(
        text: problem.comment!,
        fontSize: 14,
        color: Colors.grey[800]!,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
    );
  }

  Widget _detailPlaceholder(Color primary) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined,
              size: 36, color: primary.withValues(alpha: 0.45)),
          const SizedBox(height: 8),
          StandardText(
            text: '문제 이미지를 불러올 수 없어요',
            fontSize: 13,
            color: Colors.grey[500]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
        ],
      ),
    );
  }
}
