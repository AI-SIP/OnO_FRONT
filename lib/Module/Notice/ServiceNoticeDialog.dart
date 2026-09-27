import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Model/Notice/NoticeModel.dart';
import '../Design/AppColors.dart';
import '../Design/AppRadius.dart';
import '../Design/AppSpacing.dart';
import '../Motion/PressableScale.dart';
import '../Motion/TossDialog.dart';
import '../Text/StandardText.dart';

/// 사용자가 팝업을 어떻게 닫았는지다.
enum NoticeDialogResult {
  /// 그냥 닫았다. 다음 진입 때 다시 띄운다.
  closed,

  /// 그만 보기를 눌렀다. 서버에 숨김을 알려야 한다.
  dismissed,
}

/// 메인에 들어왔을 때 뜨는 서비스 공지 팝업이다.
///
/// 버튼이 둘이다. `닫기` 는 이번만 넘기는 것이고, `그만 보기` 는 서버에
/// 알려서 24시간 동안 이 공지를 다시 안 띄우게 한다. 어느 쪽을 눌렀는지
/// 부르는 쪽이 알아야 해서 [NoticeDialogResult] 를 돌려준다.
class ServiceNoticeDialog extends StatelessWidget {
  final NoticeModel notice;

  const ServiceNoticeDialog({super.key, required this.notice});

  static Future<NoticeDialogResult?> show(
    BuildContext context,
    NoticeModel notice,
  ) {
    return showTossDialog<NoticeDialogResult>(
      context: context,
      // 바깥을 눌러 닫는 것은 `닫기` 와 같은 뜻이라 막지 않는다.
      barrierDismissible: true,
      builder: (context) => ServiceNoticeDialog(notice: notice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _NoticeStyle.of(notice.type);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.cardPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(style),
            const SizedBox(height: AppSpacing.md),
            _buildContent(),
            if (_expiresLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              StandardText(
                text: _expiresLabel!,
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.normal,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildActions(context, style),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_NoticeStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(style.icon, size: 18, color: style.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StandardText(
            text: notice.title,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // 본문에 줄바꿈이 들어올 수 있고 최대 500자다. 긴 공지가 화면을 넘기면
    // 버튼까지 밀려 나가므로 본문만 따로 스크롤시킨다.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        child: StandardText(
          text: notice.content,
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, _NoticeStyle style) {
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: () =>
                Navigator.of(context).pop(NoticeDialogResult.dismissed),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: const StandardText(
                text: '그만 보기',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PressableScale(
            onTap: () => Navigator.of(context).pop(NoticeDialogResult.closed),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: const StandardText(
                text: '닫기',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? get _expiresLabel {
    final expiresAt = notice.expiresAt;
    if (expiresAt == null) return null;
    return '${DateFormat('M월 d일 HH:mm').format(expiresAt)}까지';
  }
}

/// 공지 종류별 아이콘과 색이다.
class _NoticeStyle {
  final IconData icon;
  final Color accent;
  final Color background;

  const _NoticeStyle({
    required this.icon,
    required this.accent,
    required this.background,
  });

  /// 모르는 종류가 늘어나도 [NoticeType.from] 에서 info 로 떨어지므로
  /// 여기서는 세 가지만 다룬다.
  static _NoticeStyle of(NoticeType type) {
    switch (type) {
      case NoticeType.warning:
        return const _NoticeStyle(
          icon: Icons.warning_amber_rounded,
          accent: Color(0xFFE8590C),
          background: Color(0xFFFFF4E6),
        );
      case NoticeType.event:
        return const _NoticeStyle(
          icon: Icons.celebration_outlined,
          accent: Color(0xFF7048E8),
          background: Color(0xFFF3F0FF),
        );
      case NoticeType.info:
        return const _NoticeStyle(
          icon: Icons.campaign_outlined,
          accent: Color(0xFF1971C2),
          background: Color(0xFFE7F5FF),
        );
    }
  }
}
