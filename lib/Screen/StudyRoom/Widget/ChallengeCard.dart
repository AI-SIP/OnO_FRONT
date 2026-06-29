import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/StudyRoom/ChallengeModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import 'ChallengeProgressBar.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final bool canDelete;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.canDelete = false,
  });

  String _daysLeft(DateTime endAt) {
    final diff = endAt.difference(DateTime.now()).inDays;
    if (diff < 0) return '종료';
    if (diff == 0) return '오늘 마감';
    return '$diff일 남음';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'individual':
        return '개인';
      case 'group':
        return '그룹';
      case 'streak':
        return '연속 출석';
      default:
        return type;
    }
  }

  String _metricLabel(String metric) {
    switch (metric) {
      case 'problem_count':
      case 'weekly_problem_count':
        return '오답노트 작성';
      case 'practice_count':
      case 'weekly_practice_count':
        return '복습 완료';
      case 'attendance':
      case 'streak':
        return '출석';
      default:
        return metric;
    }
  }

  String _periodLabel(ChallengeModel challenge) {
    if (challenge.periodDays != null) {
      return '${challenge.periodDays}일마다';
    }
    switch (challenge.period) {
      case 'daily':
        return '일간';
      case 'weekly':
        return '주간';
      case 'monthly':
        return '월간';
      case null:
        return '전체 기간';
      default:
        return challenge.period!;
    }
  }

  String _statusLabel(ChallengeModel challenge) {
    switch (challenge.status) {
      case 'in_progress':
        return _daysLeft(challenge.endAt);
      case 'completed':
        return '완료';
      case 'expired':
        return '종료';
      default:
        return challenge.status;
    }
  }

  Color _typeColor(String type, Color primary) {
    switch (type) {
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final primary = themeProvider.primaryColor;
    final c = challenge;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(15),
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _typeColor(c.type, primary).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  c.type == 'group'
                      ? Icons.groups_2_outlined
                      : c.type == 'streak'
                          ? Icons.local_fire_department_outlined
                          : Icons.flag_outlined,
                  size: 18,
                  color: _typeColor(c.type, primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: c.title,
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(text: _typeLabel(c.type)),
                        _InfoChip(text: _metricLabel(c.metric)),
                        _InfoChip(text: _periodLabel(c)),
                        _InfoChip(
                          text: _statusLabel(c),
                          color: c.isInProgress ? primary : Colors.grey[600]!,
                          backgroundColor: c.isInProgress
                              ? primary.withValues(alpha: 0.08)
                              : Colors.grey[100]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canDelete)
                GestureDetector(
                  onTap: () => _confirmDelete(context, provider),
                  child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (c.type == 'group') ...[
            ChallengeProgressBar(
              current: c.groupCurrent ?? 0,
              target: c.targetValue,
              themeProvider: themeProvider,
              label: '방 전체 합산',
            ),
          ] else ...[
            ...c.memberProgress.map(
              (mp) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChallengeProgressBar(
                  current: mp.current,
                  target: c.targetValue,
                  themeProvider: themeProvider,
                  label: mp.name,
                ),
              ),
            ),
          ],
          if (c.type == 'individual' && c.memberProgress.isNotEmpty) ...[
            const SizedBox(height: 4),
            StandardText(
              text: '${c.clearedCount} / ${c.memberProgress.length}명 달성',
              fontSize: 12,
              color: primary,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, StudyRoomProvider provider) async {
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
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '챌린지 삭제',
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StandardText(
                  text: '챌린지를 삭제하시겠어요?',
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
                          text: '취소',
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
    if (confirmed == true) {
      await provider.deleteChallenge(challenge.challengeId);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;

  const _InfoChip({
    required this.text,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: StandardText(
        text: text,
        fontSize: 10,
        color: color ?? Colors.grey[600]!,
        fontWeight: FontWeight.normal,
        fontFamily: 'PretendardLight',
      ),
    );
  }
}
