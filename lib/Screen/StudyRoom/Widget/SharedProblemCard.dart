import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/SharedProblemModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import '../../../Util/AppSnackBar.dart';
import '../../ProblemDetail/ProblemDetailScreen.dart';
import 'FeedReactionBar.dart';

class SharedProblemCard extends StatelessWidget {
  final SharedProblemModel problem;

  const SharedProblemCard({super.key, required this.problem});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  Future<void> _confirmDelete(
    BuildContext context,
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
    } catch (_) {
      if (context.mounted) AppSnackBar.showError('공유 취소에 실패했습니다');
    }
  }

  void _openProblemDetail(BuildContext context) {
    if (problem.problemId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProblemDetailScreen(problemId: problem.problemId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final primary = themeProvider.primaryColor;
    final p = problem;
    final isOwner = provider.currentUserId == p.sharedByUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.person_outline, size: 17, color: primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StandardText(
                        text: p.sharedByName,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      StandardText(
                        text: _timeAgo(p.sharedAt),
                        fontSize: 11,
                        color: Colors.grey[400]!,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'PretendardLight',
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red[300]),
                    tooltip: '공유 취소',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () =>
                        _confirmDelete(context, provider, themeProvider),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: GestureDetector(
              onTap: () => _openProblemDetail(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProblemPreview(primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StandardText(
                            text: p.reference,
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          StandardText(
                            text: p.problemId != null
                                ? '눌러서 같이 풀어보기'
                                : '문제 미리보기 없음',
                            fontSize: 11,
                            color: Colors.grey[500]!,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'PretendardLight',
                          ),
                        ],
                      ),
                    ),
                    if (p.problemId != null)
                      Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (p.comment != null && p.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: StandardText(
                text: p.comment!,
                fontSize: 13,
                color: Colors.grey[700]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: FeedReactionBar(
              reactions: p.reactions,
              themeProvider: themeProvider,
              onToggle: (emoji) =>
                  provider.toggleSharedProblemReaction(p.sharedProblemId, emoji),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemPreview(Color primary) {
    final imageUrl = problem.problemImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 46,
        height: 56,
        color: Colors.white,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderPreview(primary),
              )
            : _placeholderPreview(primary),
      ),
    );
  }

  Widget _placeholderPreview(Color primary) {
    return Container(
      width: 46,
      height: 56,
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      decoration: BoxDecoration(
        border: Border.all(color: primary.withValues(alpha: 0.18), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 5,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                height: 3,
                width: index == 2 ? 18 : 28,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: index == 0 ? 0.35 : 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
