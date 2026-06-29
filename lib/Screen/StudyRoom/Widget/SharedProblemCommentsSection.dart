import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/SharedProblemCommentModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import '../../../Util/AppSnackBar.dart';
import 'FeedReactionBar.dart';

class SharedProblemCommentsSection extends StatefulWidget {
  final int sharedProblemId;
  final int? initialCommentCount;
  final ThemeHandler themeProvider;
  final bool initiallyExpanded;
  final bool showToggle;

  const SharedProblemCommentsSection({
    super.key,
    required this.sharedProblemId,
    required this.initialCommentCount,
    required this.themeProvider,
    this.initiallyExpanded = false,
    this.showToggle = true,
  });

  @override
  State<SharedProblemCommentsSection> createState() =>
      _SharedProblemCommentsSectionState();
}

class _SharedProblemCommentsSectionState
    extends State<SharedProblemCommentsSection> {
  final TextEditingController _controller = TextEditingController();
  late bool _isExpanded;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    final provider = context.read<StudyRoomProvider>();
    if (provider.sharedProblemComments.containsKey(widget.sharedProblemId)) {
      return;
    }
    await _loadComments();
  }

  Future<void> _toggleExpanded() async {
    setState(() => _isExpanded = !_isExpanded);
    if (!_isExpanded) return;
    await _loadIfNeeded();
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
    if (!mounted) return;
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
    if (!mounted) return null;
    final controller = TextEditingController(text: initialText);
    final primary = widget.themeProvider.primaryColor;
    try {
      return await showDialog<String>(
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
                        child:
                            Icon(Icons.edit_outlined, color: primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const StandardText(
                        text: '풀이 의견 수정',
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLength: 300,
                    maxLines: 4,
                    autofocus: true,
                    style: const StandardText(
                      text: '',
                      fontSize: 14,
                      color: Colors.black87,
                    ).getTextStyle(),
                    decoration: InputDecoration(
                      hintText: '풀이 방법이나 생각을 적어보세요',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[50],
                      counterText: '',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[50],
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.grey[200]!, width: 1),
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
                          onPressed: () => Navigator.pop(
                              dialogContext, controller.text.trim()),
                          style: TextButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const StandardText(
                            text: '저장',
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
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteComment(SharedProblemCommentModel comment) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
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
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '풀이 의견 삭제',
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StandardText(
                  text: '이 의견을 삭제할까요?',
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
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                BorderSide(color: Colors.grey[200]!, width: 1),
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
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  void _showCommentActions(SharedProblemCommentModel comment) {
    if (!mounted) return;
    final primary = widget.themeProvider.primaryColor;
    showDialog<void>(
      context: context,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.forum_outlined, color: primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const StandardText(
                    text: '댓글 관리',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (comment.isMine) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _editComment(comment);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      backgroundColor: primary.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, color: primary, size: 20),
                        const SizedBox(width: 8),
                        StandardText(
                          text: '수정',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (comment.canDelete) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _deleteComment(comment);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      backgroundColor: Colors.red.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
              ],
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

  Widget _buildCommentItem(SharedProblemCommentModel comment) {
    final primary = widget.themeProvider.primaryColor;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.person_outline, size: 15, color: primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: comment.authorName,
                      fontSize: 13,
                      color: Colors.black87,
                      overflow: TextOverflow.ellipsis,
                    ),
                    StandardText(
                      text: comment.isEdited
                          ? '${_timeAgo(comment.updatedAt ?? comment.createdAt)} · 수정됨'
                          : _timeAgo(comment.createdAt),
                      fontSize: 11,
                      color: Colors.grey[500]!,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'PretendardLight',
                    ),
                  ],
                ),
              ),
              if (comment.isMine || comment.canDelete)
                IconButton(
                  icon:
                      Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showCommentActions(comment),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: StandardText(
              text: comment.content,
              fontSize: 13,
              color: Colors.grey[800]!,
            ),
          ),
          const SizedBox(height: 6),
          FeedReactionBar(
            reactions: comment.reactions,
            themeProvider: widget.themeProvider,
            onToggle: (emoji) {
              context
                  .read<StudyRoomProvider>()
                  .toggleSharedProblemCommentReaction(
                    sharedProblemId: widget.sharedProblemId,
                    commentId: comment.commentId,
                    emoji: emoji,
                  )
                  .catchError((_) {
                if (mounted) AppSnackBar.showError('댓글 반응을 남기지 못했어요');
              });
            },
          ),
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
            style: const StandardText(
              text: '',
              fontSize: 13,
              color: Colors.black87,
            ).getTextStyle(),
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
              enabledBorder: OutlineInputBorder(
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

  @override
  Widget build(BuildContext context) {
    final primary = widget.themeProvider.primaryColor;
    final comments = context
            .watch<StudyRoomProvider>()
            .sharedProblemComments[widget.sharedProblemId] ??
        const <SharedProblemCommentModel>[];
    final displayCommentCount = comments.isNotEmpty
        ? comments.length
        : (widget.initialCommentCount ?? 0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.showToggle ? 14 : 0,
        widget.showToggle ? 10 : 0,
        widget.showToggle ? 14 : 0,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showToggle)
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
                      text: '풀이 의견',
                      fontSize: 13,
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(width: 6),
                    if (displayCommentCount > 0)
                      StandardText(
                        text: '$displayCommentCount',
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
            )
          else
            Row(
              children: [
                Icon(Icons.forum_outlined, size: 17, color: primary),
                const SizedBox(width: 6),
                StandardText(
                  text: '댓글',
                  fontSize: 15,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(width: 6),
                if (displayCommentCount > 0)
                  StandardText(
                    text: '$displayCommentCount',
                    fontSize: 12,
                    color: Colors.grey[500]!,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'PretendardLight',
                  ),
              ],
            ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            if (_isLoading)
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                  ],
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
}
