import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/SharedProblemCommentModel.dart';
import '../../../Model/StudyRoom/SharedProblemModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import '../../../Util/AppSnackBar.dart';
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
                              ? '함께 보는 공유 문제'
                              : '문제 미리보기 없음',
                          fontSize: 11,
                          color: Colors.grey[500]!,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'PretendardLight',
                        ),
                      ],
                    ),
                  ),
                ],
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
          _SharedProblemCommentsSection(
            sharedProblemId: p.sharedProblemId,
            themeProvider: themeProvider,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: FeedReactionBar(
              reactions: p.reactions,
              themeProvider: themeProvider,
              onToggle: (emoji) => provider.toggleSharedProblemReaction(
                  p.sharedProblemId, emoji),
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

class _SharedProblemCommentsSection extends StatefulWidget {
  final int sharedProblemId;
  final ThemeHandler themeProvider;

  const _SharedProblemCommentsSection({
    required this.sharedProblemId,
    required this.themeProvider,
  });

  @override
  State<_SharedProblemCommentsSection> createState() =>
      _SharedProblemCommentsSectionState();
}

class _SharedProblemCommentsSectionState
    extends State<_SharedProblemCommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _loadFailed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleExpanded() async {
    setState(() => _isExpanded = !_isExpanded);
    if (!_isExpanded) return;

    final provider = context.read<StudyRoomProvider>();
    if (provider.sharedProblemComments.containsKey(widget.sharedProblemId)) {
      return;
    }
    await _loadComments();
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      await context
          .read<StudyRoomProvider>()
          .fetchSharedProblemComments(widget.sharedProblemId);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;
    if (content.length > 300) {
      AppSnackBar.showError('풀이 의견은 300자 이하로 작성해 주세요');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context
          .read<StudyRoomProvider>()
          .createSharedProblemComment(widget.sharedProblemId, content);
      _controller.clear();
    } catch (_) {
      if (mounted) AppSnackBar.showError('풀이 의견을 남기지 못했어요');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _editComment(SharedProblemCommentModel comment) async {
    final edited = await _showCommentEditDialog(comment.content);
    if (edited == null || edited == comment.content || !mounted) return;

    try {
      await context.read<StudyRoomProvider>().updateSharedProblemComment(
            sharedProblemId: widget.sharedProblemId,
            commentId: comment.commentId,
            content: edited,
          );
    } catch (_) {
      if (mounted) AppSnackBar.showError('풀이 의견을 수정하지 못했어요');
    }
  }

  Future<String?> _showCommentEditDialog(String initialText) async {
    final controller = TextEditingController(text: initialText);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const StandardText(
            text: '풀이 의견 수정',
            fontSize: 16,
            color: Colors.black87,
          ),
          content: TextField(
            controller: controller,
            maxLength: 300,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '풀이 방법이나 생각을 적어보세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(
                '저장',
                style: TextStyle(
                  color: widget.themeProvider.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteComment(SharedProblemCommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const StandardText(
          text: '풀이 의견 삭제',
          fontSize: 16,
          color: Colors.black87,
        ),
        content: StandardText(
          text: '이 의견을 삭제할까요?',
          fontSize: 14,
          color: Colors.grey[700]!,
          fontWeight: FontWeight.normal,
          fontFamily: 'PretendardLight',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<StudyRoomProvider>().deleteSharedProblemComment(
            sharedProblemId: widget.sharedProblemId,
            commentId: comment.commentId,
          );
    } catch (_) {
      if (mounted) AppSnackBar.showError('풀이 의견을 삭제하지 못했어요');
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.themeProvider.primaryColor;
    final comments = context
            .watch<StudyRoomProvider>()
            .sharedProblemComments[widget.sharedProblemId] ??
        const <SharedProblemCommentModel>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, size: 17, color: primary),
                  const SizedBox(width: 6),
                  StandardText(
                    text: _isExpanded ? '풀이 의견 접기' : '풀이 의견 보기',
                    fontSize: 13,
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(width: 6),
                  if (comments.isNotEmpty)
                    StandardText(
                      text: '${comments.length}',
                      fontSize: 12,
                      color: Colors.grey[500]!,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'PretendardLight',
                    ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                ),
              )
            else if (_loadFailed)
              _buildCommentNotice(
                icon: Icons.info_outline,
                message: '풀이 의견을 불러오지 못했어요',
                actionLabel: '다시 시도',
                onAction: _loadComments,
              )
            else ...[
              if (comments.isEmpty)
                _buildCommentNotice(
                  icon: Icons.chat_bubble_outline,
                  message: '아직 풀이 의견이 없어요',
                )
              else
                ...comments.map(_buildCommentItem),
              const SizedBox(height: 10),
              _buildCommentInput(primary),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCommentNotice({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: StandardText(
              text: message,
              fontSize: 13,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: StandardText(
                text: actionLabel,
                fontSize: 12,
                color: widget.themeProvider.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(SharedProblemCommentModel comment) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StandardText(
                  text: comment.authorName,
                  fontSize: 12,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StandardText(
                text: comment.isEdited
                    ? '${_timeAgo(comment.updatedAt ?? comment.createdAt)} 수정'
                    : _timeAgo(comment.createdAt),
                fontSize: 11,
                color: Colors.grey[500]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
              if (comment.isMine)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon:
                      Icon(Icons.more_vert, size: 17, color: Colors.grey[500]),
                  onSelected: (value) {
                    if (value == 'edit') _editComment(comment);
                    if (value == 'delete') _deleteComment(comment);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 5),
          StandardText(
            text: comment.content,
            fontSize: 13,
            color: Colors.grey[800]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(Color primary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '풀이 의견 남기기',
              counterText: '',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          height: 40,
          child: TextButton(
            onPressed: _isSubmitting ? null : _submitComment,
            style: TextButton.styleFrom(
              backgroundColor: _isSubmitting ? Colors.grey[300] : primary,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
