import 'package:flutter/material.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Motion/TossDialog.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Util/AppAnalytics.dart';
import '../../../Util/AppNavigator.dart';
import '../../../Util/NotificationService.dart';
import '../../ProblemDetail/ProblemDetailScreen.dart';

/// 첫 오답노트를 쓴 뒤 다음에 무엇을 하면 되는지 알려 준다.
///
/// 새 오답노트는 한 번 다시 풀어야 다음 복습일이 잡히고 추천 복습에 들어간다.
/// 전에는 저장했다는 알림만 떠서, 처음 쓴 사람은 그다음에 무엇을 해야 하는지
/// 몰랐다. [지금 풀기] 를 누르면 방금 쓴 오답노트 상세를 연다.
///
/// 등록 화면이 닫힌 뒤에 띄우므로 앱 맨 위 navigator 를 쓴다.
Future<void> showFirstNoteGuide({
  required int problemId,
  required Color accentColor,
}) async {
  final context = AppNavigator.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  final solveNow = await showTossDialog<bool>(
    context: context,
    builder: (dialogContext) => _FirstNoteGuideDialog(accentColor: accentColor),
  );
  AppAnalytics.logEvent('first_note_guide', {
    'choice': solveNow == true ? 'solve_now' : 'later',
  });
  // 복습할 날을 알려 준다고 막 말한 자리라, 알림 권한을 여기서 묻는다.
  await NotificationService.instance
      .requestPermissionIfNeeded(source: 'first_note');
  if (solveNow != true) return;

  final navigator = AppNavigator.navigatorKey.currentState;
  navigator?.push(
    TossPageRoute(builder: (_) => ProblemDetailScreen(problemId: problemId)),
  );
}

class _FirstNoteGuideDialog extends StatelessWidget {
  final Color accentColor;

  const _FirstNoteGuideDialog({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        // 글자를 크게 키운 작은 폰에서는 창이 화면보다 길어질 수 있다.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_repeat, color: accentColor, size: 28),
              ),
              const SizedBox(height: 14),
              const StandardText(
                text: '첫 오답노트를 썼어요',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const StandardText(
                text: '오늘 한 번 다시 풀면 복습 일정이 시작돼요.\n'
                    '맞힌 만큼 다음 복습일을 잡아서 그날 추천해 드려요.',
                fontSize: 14,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
                height: 1.5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: const StandardText(
                    text: '지금 풀기',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(minimumSize: const Size(88, 44)),
                child: const StandardText(
                  text: '나중에 할게요',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
