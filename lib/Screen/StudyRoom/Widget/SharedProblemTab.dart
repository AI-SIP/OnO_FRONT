import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
import '../../../Util/AppSnackBar.dart';
import '../ProblemPickerScreen.dart';
import 'SharedProblemCard.dart';

class SharedProblemTab extends StatefulWidget {
  final int roomId;

  const SharedProblemTab({super.key, required this.roomId});

  @override
  State<SharedProblemTab> createState() => _SharedProblemTabState();
}

class _SharedProblemTabState extends State<SharedProblemTab>
    with AutomaticKeepAliveClientMixin {
  bool _loaded = false;
  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      if (provider.sharedProblemsHasNext &&
          !provider.isSharedProblemsLoadingMore) {
        provider.loadMoreSharedProblems(widget.roomId);
      }
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    await provider.fetchSharedProblems(widget.roomId);
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _openPicker(
    BuildContext context,
    ThemeHandler themeProvider,
  ) async {
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    final alreadySharedIds = provider.sharedProblems
        .map((s) => s.problemId)
        .whereType<int>()
        .toSet();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProblemPickerScreen(
          roomId: widget.roomId,
          alreadySharedProblemIds: alreadySharedIds,
        ),
      ),
    );
    if (result == true && context.mounted) {
      AppSnackBar.messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const StandardText(
            text: '문제를 공유했어요!',
            fontSize: 14,
            color: Colors.white,
          ),
          backgroundColor: themeProvider.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final provider = Provider.of<StudyRoomProvider>(context);

    if (!_loaded) {
      return Center(
        child: CircularProgressIndicator(color: themeProvider.primaryColor),
      );
    }

    return Column(
      children: [
        _buildBoardHeader(
          context,
          themeProvider,
          provider.sharedProblems.length,
        ),
        Expanded(
          child: provider.sharedProblems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              themeProvider.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.share_outlined,
                          color: themeProvider.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const StandardText(
                        text: '공유된 문제가 없어요',
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 6),
                      StandardText(
                        text: '내 오답노트 문제를 룸에 공유해보세요',
                        fontSize: 13,
                        color: Colors.grey[500]!,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'PretendardLight',
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 18),
                  itemCount: provider.sharedProblems.length +
                      (provider.sharedProblemsHasNext ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == provider.sharedProblems.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: themeProvider.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    return SharedProblemCard(
                      problem: provider.sharedProblems[i],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBoardHeader(
    BuildContext context,
    ThemeHandler themeProvider,
    int problemCount,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.forum_outlined,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StandardText(
                  text: '문제 공유 게시판',
                  fontSize: 15,
                  color: Colors.black87,
                ),
                const SizedBox(height: 3),
                StandardText(
                  text: '공유 문제 $problemCount개',
                  fontSize: 12,
                  color: Colors.grey[500]!,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _openPicker(context, themeProvider),
            style: TextButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.upload_outlined, size: 17),
            label: const StandardText(
              text: '공유',
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
