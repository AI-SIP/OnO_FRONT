import 'package:flutter/material.dart';

import '../../../Model/StudyRoom/WeeklyReportModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class WeeklyReportSheet extends StatelessWidget {
  final WeeklyReportModel report;
  final ThemeHandler themeProvider;

  const WeeklyReportSheet({
    super.key,
    required this.report,
    required this.themeProvider,
  });

  static Future<void> show(
    BuildContext context,
    WeeklyReportModel report,
    ThemeHandler themeProvider, {
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WeeklyReportSheet(
        report: report,
        themeProvider: themeProvider,
      ),
    ).whenComplete(() => onClose?.call());
  }

  @override
  Widget build(BuildContext context) {
    final primary = themeProvider.primaryColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.summarize_outlined,
                          color: primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const StandardText(
                            text: '주간 리포트',
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          StandardText(
                            text: '지난 7일 활동 요약',
                            fontSize: 13,
                            color: Colors.grey[500]!,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'PretendardLight',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _StatCard(
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                    title: '이번 주 1등',
                    value: report.topMemberName,
                    sub: '${report.topMemberProblemCount}문제 등록',
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.deepOrange,
                    title: '최장 연속 출석',
                    value: report.longestStreakName,
                    sub: '${report.longestStreakDays}일 연속',
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.menu_book,
                          label: '총 문제 수',
                          value: '${report.totalProblems}문제',
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.flag,
                          label: '달성 챌린지',
                          value: '${report.challengesCompleted}개',
                          primary: primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StandardText(
                            text: report.cheerMessage,
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'PretendardLight',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 16,
                      color: Colors.white,
                    ),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String sub;
  final ThemeHandler themeProvider;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.sub,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: title,
                  fontSize: 12,
                  color: Colors.grey[500]!,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
                const SizedBox(height: 2),
                StandardText(
                  text: value,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
          StandardText(
            text: sub,
            fontSize: 13,
            color: themeProvider.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 16),
          const SizedBox(height: 6),
          StandardText(
            text: label,
            fontSize: 12,
            color: Colors.grey[500]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
          const SizedBox(height: 2),
          StandardText(
            text: value,
            fontSize: 16,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}
