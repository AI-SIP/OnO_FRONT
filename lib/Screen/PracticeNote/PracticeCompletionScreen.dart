import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../Module/Emoji/OnoEmojiCatalog.dart';
import '../../Module/Emoji/OnoEmojiImage.dart';
import '../../Module/Emoji/OnoEmojiPicker.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';

class PracticeCompletionScreen extends StatefulWidget {
  final int practiceId;
  final int totalProblems;
  final int practiceRound;

  const PracticeCompletionScreen({
    super.key,
    required this.practiceId,
    required this.totalProblems,
    required this.practiceRound,
  });

  @override
  State<PracticeCompletionScreen> createState() =>
      _PracticeCompletionScreenState();
}

class _PracticeCompletionScreenState extends State<PracticeCompletionScreen> {
  static const List<String> _recommendedMoodKeys = [
    'success_checkmark',
    'got_100_score',
    'fired_up_sparkle_eyes',
    'happy_tears',
    'frustrated_studying',
    'stressed_bomb',
    'dizzy_spiral_eyes2',
    'sleeping_blanket',
  ];

  String? _selectedMoodKey;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(themeProvider),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: buildCompletionContent(screenHeight, themeProvider),
          ),
          buildConfirmationButton(context, themeProvider, practiceProvider),
        ],
      ),
    );
  }

  AppBar buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      title: StandardText(
        text: '복습 완료',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget buildCompletionContent(
      double screenHeight, ThemeHandler themeProvider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.2),
            Center(
              child: SvgPicture.asset(
                'assets/Icon/BigGreenFrog.svg',
                height: screenHeight * 0.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.1),
            StandardText(
              text: '${widget.practiceRound}회차 복습을 완료했어요',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01),
            StandardText(
              text: '총 ${widget.totalProblems}문제를 풀었어요.',
              fontSize: 16,
              color: Colors.black54,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.06),
            _buildMoodSection(themeProvider),
            SizedBox(height: screenHeight * 0.08),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(ThemeHandler themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        const StandardText(
          text: '이번 복습 어땠나요?',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedMoodKeys.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _recommendedMoodKeys.length) {
                return _buildMoreMoodButton(themeProvider);
              }

              final emojiKey = _recommendedMoodKeys[index];
              final emoji = OnoEmojiCatalog.byKey(emojiKey);
              if (emoji == null) return const SizedBox.shrink();

              final isSelected = _selectedMoodKey == emojiKey;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMoodKey = isSelected ? null : emojiKey;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeProvider.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      OnoEmojiImage(emoji: emoji, size: 46),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeProvider.primaryColor
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMoodButton(ThemeHandler themeProvider) {
    return InkWell(
      onTap: () {
        OnoEmojiPicker.show(
          context,
          selectedKey: _selectedMoodKey,
          onSelected: (emoji) => setState(() => _selectedMoodKey = emoji.key),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Icon(
          Icons.more_horiz,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget buildConfirmationButton(BuildContext context,
      ThemeHandler themeProvider, ProblemPracticeProvider practiceProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await practiceProvider.addPracticeCount(
                widget.practiceId,
                moodEmojiKey: _selectedMoodKey,
              );
            } catch (_) {
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: StandardText(
                    text: '복습 완료를 저장하지 못했어요.',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (!mounted) return;
            // 2번 pop: PracticeCompletionScreen -> PracticeDetailScreen -> PracticeThumbnailScreen
            // 두 번째 pop에서 true를 반환하여 썸네일 업데이트 신호 전달
            if (navigator.canPop()) {
              navigator.pop(); // PracticeCompletionScreen 닫기
            }
            if (navigator.canPop()) {
              navigator.pop(true); // PracticeDetailScreen 닫으면서 true 반환
            }
            messenger.showSnackBar(
              SnackBar(
                content: const StandardText(
                  text: '복습을 완료했습니다!',
                  fontSize: 14,
                  color: Colors.white,
                ),
                backgroundColor: themeProvider.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const StandardText(
            text: "확인",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
