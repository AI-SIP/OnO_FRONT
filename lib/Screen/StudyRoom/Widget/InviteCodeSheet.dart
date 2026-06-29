import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../Model/StudyRoom/InviteCodeModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class InviteCodeSheet extends StatelessWidget {
  final InviteCodeModel inviteCode;
  final ThemeHandler themeProvider;

  const InviteCodeSheet({
    super.key,
    required this.inviteCode,
    required this.themeProvider,
  });

  static Future<void> show(
    BuildContext context, {
    required InviteCodeModel inviteCode,
    required ThemeHandler themeProvider,
  }) {
    return showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: '초대 코드 닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => _DismissibleBottomSheetFrame(
        child: InviteCodeSheet(
          inviteCode: inviteCode,
          themeProvider: themeProvider,
        ),
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiry =
        DateFormat('MM/dd HH:mm').format(inviteCode.expiredAt.toLocal());
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  Icons.key_outlined,
                  color: themeProvider.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const StandardText(
                text: '초대 코드',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          StandardText(
            text: '만료: $expiry',
            fontSize: 13,
            color: Colors.grey[500]!,
            fontWeight: FontWeight.normal,
            fontFamily: 'PretendardLight',
          ),
          SizedBox(height: screenHeight * 0.025),
          Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.028),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: themeProvider.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: StandardText(
                text: _formatCode(inviteCode.code),
                fontSize: 34,
                color: themeProvider.primaryColor,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _copyCode(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      StandardText(
                        text: '코드 복사',
                        fontSize: 14,
                        color: Colors.grey[700]!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () => _shareCode(context),
                  style: TextButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      StandardText(
                          text: '공유하기', fontSize: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SafeArea(top: false, child: SizedBox(height: screenHeight * 0.015)),
        ],
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const StandardText(
          text: '초대 코드가 복사되었어요!',
          fontSize: 14,
          color: Colors.white,
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareCode(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize && !box.size.isEmpty
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
            1,
            1,
          );

    await Share.share(
      'OnO 스터디룸 초대 코드: ${inviteCode.code}',
      sharePositionOrigin: origin,
    );
  }
}

class _DismissibleBottomSheetFrame extends StatefulWidget {
  final Widget child;

  const _DismissibleBottomSheetFrame({required this.child});

  @override
  State<_DismissibleBottomSheetFrame> createState() =>
      _DismissibleBottomSheetFrameState();
}

class _DismissibleBottomSheetFrameState
    extends State<_DismissibleBottomSheetFrame> {
  bool _canDismissByOutsideTap = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _canDismissByOutsideTap = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sheetWidth = screenWidth < 600 ? screenWidth : 560.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _canDismissByOutsideTap
                  ? () => Navigator.maybePop(context)
                  : null,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: SizedBox(
                width: sheetWidth,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
