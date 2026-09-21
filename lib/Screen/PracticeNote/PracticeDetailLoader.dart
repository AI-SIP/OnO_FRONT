import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Motion/Skeleton.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';
import '../../Util/AppAnalytics.dart';
import 'PracticeDetailScreen.dart';

/// 복습 세트 화면을 먼저 열고, 그 안에서 세트를 불러온다.
///
/// 전에는 목록에서 누르면 세트와 문제를 다 불러온 뒤에야 화면이 넘어갔다.
/// 그동안 아무것도 바뀌지 않아서 다른 세트를 또 누를 수 있었고, 그러면 두
/// 화면이 겹쳐 쌓였다. 화면이 바로 넘어가면 목록은 그 뒤로 가려진다.
///
/// 복습을 마치고 `true` 로 닫히는 것은 [PracticeDetailScreen] 이 이 경로를
/// 그대로 닫으므로 부른 쪽이 똑같이 받는다.
class PracticeDetailLoader extends StatefulWidget {
  final int practiceId;

  /// 불러오는 동안 앱바에 적을 세트 이름. 목록에서 이미 알고 있다.
  final String? title;

  const PracticeDetailLoader({
    super.key,
    required this.practiceId,
    this.title,
  });

  @override
  State<PracticeDetailLoader> createState() => _PracticeDetailLoaderState();
}

class _PracticeDetailLoaderState extends State<PracticeDetailLoader> {
  PracticeNoteDetailModel? _practice;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // 세트 화면은 StatelessWidget 이라 여기서 남긴다. 알림으로 바로 여는
    // 경로는 NotificationService 에서 따로 남긴다.
    AppAnalytics.logScreenView('PracticeDetailScreen');
    _load();
  }

  Future<void> _load() async {
    final provider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    if (_failed) setState(() => _failed = false);

    try {
      await provider.fetchPracticeNote(widget.practiceId);
      await provider.moveToPractice(widget.practiceId);
    } catch (error) {
      debugPrint('Failed to open practice ${widget.practiceId}: $error');
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;

    final practice = provider.currentPracticeNote;
    setState(() {
      if (practice != null && practice.practiceId == widget.practiceId) {
        _practice = practice;
      } else {
        _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final practice = _practice;
    if (practice != null) return PracticeDetailScreen(practice: practice);

    final themeProvider = Provider.of<ThemeHandler>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: StandardText(
          text: widget.title ?? '',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: _failed ? _buildFailed(themeProvider) : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SkeletonBox(height: 44),
        ),
        Divider(),
        Expanded(
          child: SkeletonList(
            itemCount: 4,
            itemHeight: 96,
            spacing: 16,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed(ThemeHandler themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StandardText(
              text: '복습 세트를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.',
              fontSize: 15,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              child: const StandardText(
                text: '다시 불러오기',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
