import 'package:flutter/material.dart';

import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'ProblemSolveCanvasScreen.dart';
import 'ProblemSolveRegisterScreen.dart';

class ProblemSolveEntry {
  static Future<bool?> open({
    required BuildContext context,
    required int problemId,
    required List<String> problemImageUrls,
    required VoidCallback onRefresh,
    required ThemeHandler themeProvider,
  }) async {
    final mode = await showModalBottomSheet<_ProblemSolveMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProblemSolveModeSheet(
        problemImageCount: problemImageUrls.length,
        themeProvider: themeProvider,
      ),
    );

    if (mode == null || !context.mounted) {
      return null;
    }

    if (mode == _ProblemSolveMode.offline) {
      return Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProblemSolveRegisterScreen(
            problemId: problemId,
            onRefresh: onRefresh,
          ),
        ),
      );
    }

    if (problemImageUrls.isEmpty) {
      return Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProblemSolveRegisterScreen(
            problemId: problemId,
            onRefresh: onRefresh,
          ),
        ),
      );
    }

    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemSolveCanvasScreen(
          problemId: problemId,
          problemImageUrls: problemImageUrls,
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

enum _ProblemSolveMode {
  offline,
  inApp,
}

class _ProblemSolveModeSheet extends StatelessWidget {
  final int problemImageCount;
  final ThemeHandler themeProvider;

  const _ProblemSolveModeSheet({
    required this.problemImageCount,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: themeProvider.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              StandardText(
                text: '다시 풀기 방식 선택',
                fontSize: MobileFontSize.reduced(context, 20),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ModeTile(
            icon: Icons.photo_camera_outlined,
            title: '현장에서 풀었어요',
            description: '종이나 다른 앱에서 푼 풀이 이미지를 직접 등록합니다.',
            themeProvider: themeProvider,
            onTap: () => Navigator.pop(context, _ProblemSolveMode.offline),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.draw,
            title: '앱에서 바로 풀기',
            description: problemImageCount == 0
                ? '문제 이미지가 있어야 사용할 수 있습니다.'
                : '문제 이미지 $problemImageCount장 위에 필기하고 풀이 시간도 자동 기록합니다.',
            themeProvider: themeProvider,
            isEnabled: problemImageCount > 0,
            onTap: () => Navigator.pop(context, _ProblemSolveMode.inApp),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ThemeHandler themeProvider;
  final VoidCallback onTap;
  final bool isEnabled;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.themeProvider,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? themeProvider.primaryColor : Colors.grey;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.grey[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEnabled
                ? themeProvider.primaryColor.withOpacity(0.18)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: title,
                    fontSize:
                        isEnabled ? MobileFontSize.reduced(context, 16) : 16,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.black87 : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  StandardText(
                    text: description,
                    fontSize: 13,
                    color: isEnabled ? Colors.black54 : Colors.grey,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isEnabled ? Colors.grey[500] : Colors.grey[350],
            ),
          ],
        ),
      ),
    );
  }
}
