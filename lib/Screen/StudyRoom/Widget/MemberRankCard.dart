import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/StudyRoomMemberModel.dart';
import '../../../Module/Emoji/OnoEmojiImage.dart';
import '../../../Module/Emoji/OnoEmojiPicker.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class MemberRankCard extends StatefulWidget {
  final int rank;
  final StudyRoomMemberModel member;
  final bool isMe;
  final bool isHost;
  final bool canKick;
  final VoidCallback? onKick;

  const MemberRankCard({
    super.key,
    required this.rank,
    required this.member,
    required this.isMe,
    required this.isHost,
    this.canKick = false,
    this.onKick,
  });

  @override
  State<MemberRankCard> createState() => _MemberRankCardState();
}

class _MemberRankCardState extends State<MemberRankCard>
    with SingleTickerProviderStateMixin {
  String? _flyingEmoji;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _flyingEmoji = null);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _sendReaction(String emojiKey) {
    setState(() => _flyingEmoji = emojiKey);
    _animController.forward(from: 0);
  }

  void _showReactionSheet() {
    OnoEmojiPicker.show(
      context,
      onSelected: (emoji) => _sendReaction(emoji.key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final m = widget.member;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(screenHeight * 0.016),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? themeProvider.primaryColor.withValues(alpha: 0.055)
                  : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: widget.isMe
                    ? themeProvider.primaryColor.withValues(alpha: 0.35)
                    : Colors.grey[300]!,
                width: widget.isMe ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isMe
                      ? themeProvider.primaryColor.withValues(alpha: 0.10)
                      : Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildRankBadge(themeProvider),
                const SizedBox(width: 10),
                _buildAvatar(m, themeProvider),
                SizedBox(width: screenHeight * 0.012),
                Expanded(child: _buildMemberInfo(m, themeProvider)),
                _buildStats(m, themeProvider),
                const SizedBox(width: 4),
                _buildReactionButton(themeProvider),
              ],
            ),
          ),
          if (_flyingEmoji != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (_, __) => Opacity(
                      opacity: _opacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: OnoEmojiImage(
                          emojiKey: _flyingEmoji,
                          size: 46,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(ThemeHandler themeProvider) {
    final isTop3 = widget.rank <= 3;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isTop3 ? themeProvider.primaryColor : Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: StandardText(
          text: '${widget.rank}',
          fontSize: 12,
          color: isTop3 ? Colors.white : Colors.grey[500]!,
        ),
      ),
    );
  }

  Widget _buildAvatar(
    StudyRoomMemberModel m,
    ThemeHandler themeProvider,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: widget.isMe
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          widget.isMe ? Icons.person : Icons.person_outline,
          size: 19,
          color: widget.isMe ? Colors.white : themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMemberInfo(StudyRoomMemberModel m, ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: StandardText(
                text: m.name,
                fontSize: 15,
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: StandardText(
                  text: '나',
                  fontSize: 11,
                  color: themeProvider.primaryColor,
                ),
              ),
            ],
            if (widget.isHost) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.workspace_premium_outlined,
                size: 13,
                color: themeProvider.primaryColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star, size: 12, color: themeProvider.primaryColor),
            const SizedBox(width: 3),
            StandardText(
              text: 'Lv.${m.totalStudyLevel}',
              fontSize: 12,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.local_fire_department_rounded,
              size: 12,
              color: Colors.deepOrange[300],
            ),
            const SizedBox(width: 3),
            StandardText(
              text: '${m.currentStreak}일',
              fontSize: 12,
              color: Colors.grey[600]!,
              fontWeight: FontWeight.normal,
              fontFamily: 'PretendardLight',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(StudyRoomMemberModel m, ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StandardText(
            text: '${m.weeklyProblemCount}',
            fontSize: 16,
            color: themeProvider.primaryColor,
            fontWeight: FontWeight.w700,
          ),
          StandardText(
            text: '문제',
            fontSize: 10,
            color: Colors.grey[600]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(ThemeHandler themeProvider) {
    return InkWell(
      onTap: _showReactionSheet,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Icon(
          Icons.favorite_border_rounded,
          size: 17,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }
}
