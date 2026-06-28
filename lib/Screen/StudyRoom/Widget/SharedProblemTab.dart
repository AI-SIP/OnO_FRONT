import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/StudyRoomProvider.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    await provider.fetchSharedProblems(widget.roomId);
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _openPicker(BuildContext context, ThemeHandler themeProvider) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProblemPickerScreen(roomId: widget.roomId),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문제를 공유했어요!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
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
                          color: themeProvider.primaryColor.withOpacity(0.1),
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: provider.sharedProblems.length,
                  itemBuilder: (_, i) =>
                      SharedProblemCard(problem: provider.sharedProblems[i]),
                ),
        ),
        _buildShareButton(context, themeProvider),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context, ThemeHandler themeProvider) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 92, 12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: () => _openPicker(context, themeProvider),
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
                Icon(Icons.upload_outlined, size: 18, color: Colors.white),
                SizedBox(width: 6),
                StandardText(
                  text: '문제 공유하기',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
