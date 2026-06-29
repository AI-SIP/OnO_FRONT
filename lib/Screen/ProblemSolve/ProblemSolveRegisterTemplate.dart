import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/AnswerStatus.dart';
import '../../Model/Problem/ImprovementType.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/mobile_font_size.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ProblemsProvider.dart';
import '../ProblemRegister/Widget/ImageGridWidget.dart';

class ProblemSolveRegisterTemplate extends StatefulWidget {
  final int problemId;
  final List<File> initialSolutionImages;
  final int? initialTimeSpentSeconds;

  const ProblemSolveRegisterTemplate({
    Key? key,
    required this.problemId,
    this.initialSolutionImages = const [],
    this.initialTimeSpentSeconds,
  }) : super(key: key);

  @override
  ProblemSolveRegisterTemplateState createState() =>
      ProblemSolveRegisterTemplateState();
}

class ProblemSolveRegisterTemplateState
    extends State<ProblemSolveRegisterTemplate> {
  final _memoCtrl = TextEditingController();
  final List<XFile> _solutionImages = [];
  AnswerStatus _answerStatus = AnswerStatus.CORRECT; // 정답 상태 (기본값: 정답)
  int _timeSpentSeconds = 10 * 60; // 소요 시간 (초)
  List<String> _answerImageUrls = [];

  // 개선 체크리스트 (ImprovementType enum 사용)
  final Map<ImprovementType, bool> _improvements = {
    ImprovementType.NO_REPEAT_MISTAKE: false,
    ImprovementType.FOUND_NEW_SOLUTION: false,
    ImprovementType.BETTER_UNDERSTANDING: false,
    ImprovementType.FASTER_SOLVING: false,
  };

  @override
  void initState() {
    super.initState();
    _solutionImages.addAll(
      widget.initialSolutionImages.map((file) => XFile(file.path)),
    );
    _timeSpentSeconds = widget.initialTimeSpentSeconds ?? _timeSpentSeconds;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnswerImages());
  }

  Future<void> _loadAnswerImages() async {
    if (!mounted) return;
    final provider = Provider.of<ProblemsProvider>(context, listen: false);
    try {
      final problem = await provider.getProblem(widget.problemId);
      if (mounted) {
        setState(() {
          _answerImageUrls = problem.answerImageDataList
                  ?.map((img) => img.imageUrl)
                  .toList() ??
              [];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final isWide = MediaQuery.of(context).size.width >= 600;
    final spacing = isWide ? 50.0 : 30.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // 복습 완료 헤더
            _buildCompletionHeader(themeProvider),
            SizedBox(height: spacing),

            // 정답 여부 선택
            _buildAnswerStatusSection(themeProvider),
            SizedBox(height: spacing),

            // 소요 시간 입력
            _buildTimeSpentSection(themeProvider),
            SizedBox(height: spacing),

            // 풀이 이미지 업로드
            _buildImageSection(themeProvider),
            SizedBox(height: spacing),

            // 개선된 점 체크리스트
            _buildImprovementSection(themeProvider),
            SizedBox(height: spacing),

            // 복습 메모
            _buildReflectionSection(themeProvider),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionHeader(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: themeProvider.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: '문제 복습 완료!',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(height: 4),
                const StandardText(
                  text: '복습 내용을 기록해보세요',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeHandler themeProvider) {
    return _buildSectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.image,
            title: '풀이 이미지',
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          ImageGridWidget(
            label: '풀이 이미지',
            files: _solutionImages,
            existingImageUrls: const [],
            onAdd: _pickSolutionImage,
            onRemove: (i) => setState(() => _solutionImages.removeAt(i)),
            onRemoveExisting: (i) {},
            showHeader: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerStatusSection(ThemeHandler themeProvider) {
    return _buildSectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                icon: Icons.check_circle_outline,
                title: '이번 복습 결과',
                themeProvider: themeProvider,
              ),
              if (_answerImageUrls.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showAnswerImages(context),
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 15,
                    color: themeProvider.primaryColor,
                  ),
                  label: StandardText(
                    text: '정답 보기',
                    fontSize: 13,
                    color: themeProvider.primaryColor,
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnswerOption(
                  label: '정답',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isSelected: _answerStatus == AnswerStatus.CORRECT,
                  onTap: () =>
                      setState(() => _answerStatus = AnswerStatus.CORRECT),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnswerOption(
                  label: '부분 정답',
                  icon: Icons.check_circle_outline,
                  color: Colors.orange,
                  isSelected: _answerStatus == AnswerStatus.PARTIAL,
                  onTap: () =>
                      setState(() => _answerStatus = AnswerStatus.PARTIAL),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnswerOption(
                  label: '오답',
                  icon: Icons.cancel,
                  color: Colors.red,
                  isSelected: _answerStatus == AnswerStatus.WRONG,
                  onTap: () =>
                      setState(() => _answerStatus = AnswerStatus.WRONG),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            StandardText(
              text: label,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSection(ThemeHandler themeProvider) {
    return _buildSectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.trending_up,
            title: '개선된 점',
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 4),
          const StandardText(
            text: '해당되는 항목을 선택해주세요 (선택사항)',
            fontSize: 13,
            color: Colors.black54,
          ),
          const SizedBox(height: 12),
          Column(
            children: _improvements.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildCheckboxItem(
                  label: entry.key,
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _improvements[entry.key] = value ?? false;
                    });
                  },
                  themeProvider: themeProvider,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem({
    required ImprovementType label,
    required bool value,
    required Function(bool?) onChanged,
    required ThemeHandler themeProvider,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: value
                ? themeProvider.primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: themeProvider.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: label.description,
                fontSize: 14,
                color: value ? Colors.black87 : Colors.black54,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSpentSection(ThemeHandler themeProvider) {
    return _buildSectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.timer_outlined,
            title: '소요 시간',
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showTimeInputDialog,
                  child: Container(
                    color: Colors.transparent,
                    child: StandardText(
                      text: _timeSpentSeconds > 0
                          ? _formatTimeSpent(_timeSpentSeconds)
                          : '직접 입력',
                      fontSize: 14,
                      color: _timeSpentSeconds > 0
                          ? Colors.black87
                          : Colors.grey[400]!,
                    ),
                  ),
                ),
                const Spacer(),
                _buildAdjustChip('-1분', themeProvider, () {
                  setState(() {
                    _timeSpentSeconds -= 60;
                    if (_timeSpentSeconds < 0) _timeSpentSeconds = 0;
                  });
                }),
                const SizedBox(width: 4),
                _buildAdjustChip('+1분', themeProvider,
                    () => setState(() => _timeSpentSeconds += 60)),
                const SizedBox(width: 8),
                _buildAdjustChip('-10초', themeProvider, () {
                  setState(() {
                    _timeSpentSeconds -= 10;
                    if (_timeSpentSeconds < 0) _timeSpentSeconds = 0;
                  });
                }),
                const SizedBox(width: 4),
                _buildAdjustChip('+10초', themeProvider,
                    () => setState(() => _timeSpentSeconds += 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustChip(
      String label, ThemeHandler themeProvider, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: themeProvider.primaryColor.withOpacity(0.25), width: 1),
        ),
        child: StandardText(
          text: label,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  Widget _buildReflectionSection(ThemeHandler themeProvider) {
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    return _buildSectionBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.edit,
            title: '복습 메모',
            themeProvider: themeProvider,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoCtrl,
            maxLines: 5,
            style: standardTextStyle.copyWith(
              color: Colors.black87,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: themeProvider.primaryColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
              hintText: '이번 복습에서 느낀 점을 자유롭게 작성해주세요!',
              hintStyle: standardTextStyle.copyWith(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerImages(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AnswerImagesScreen(imageUrls: _answerImageUrls),
      ),
    );
  }

  int? _parseTimeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final m = int.tryParse(parts[0].trim());
        final s = int.tryParse(parts[1].trim());
        if (m != null && s != null && s >= 0 && s < 60) {
          return m * 60 + s;
        }
      }
      return null;
    }
    final m = int.tryParse(trimmed);
    return (m != null && m >= 0) ? m * 60 : null;
  }

  Future<void> _showTimeInputDialog() async {
    final minutes = _timeSpentSeconds ~/ 60;
    final seconds = _timeSpentSeconds % 60;
    final initialText = _timeSpentSeconds > 0
        ? (seconds > 0
            ? '$minutes:${seconds.toString().padLeft(2, '0')}'
            : '$minutes')
        : '';
    final controller = TextEditingController(text: initialText);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final standardTextStyle = const StandardText(text: '').getTextStyle();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StandardText(
                      text: '소요 시간 입력',
                      fontSize: MobileFontSize.reduced(context, 20),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const StandardText(
                  text: '분:초(예: 3:47) 또는 분(예: 17) 형식으로 입력하세요',
                  fontSize: 14,
                  color: Colors.black54,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: standardTextStyle.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '예: 3:47 또는 17',
                    hintStyle: standardTextStyle.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: themeProvider.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: StandardText(
                          text: '취소',
                          fontSize: MobileFontSize.reduced(context, 15),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          final parsed = _parseTimeInput(controller.text);
                          if (parsed != null) {
                            setState(() => _timeSpentSeconds = parsed);
                          }
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: themeProvider.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '확인',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required ThemeHandler themeProvider,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: themeProvider.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        StandardText(
          text: title,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ],
    );
  }

  Widget _buildSectionBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: child,
    );
  }

  Future<void> _pickSolutionImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          setState(() => _solutionImages.add(file));
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        setState(() => _solutionImages.addAll(files));
      },
    );
  }

  // API 연동 시 사용할 데이터 수집 메서드
  Map<String, dynamic> getReviewData() {
    return {
      'problemId': widget.problemId,
      'answerStatus': _answerStatus,
      'reflection': _memoCtrl.text.isNotEmpty ? _memoCtrl.text : null,
      'solutionImages': _solutionImages.map((f) => File(f.path)).toList(),
      'improvements': _improvements.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      'timeSpentSeconds': _timeSpentSeconds > 0 ? _timeSpentSeconds : null,
    };
  }

  void resetAll() {
    setState(() {
      _memoCtrl.clear();
      _solutionImages.clear();
      _answerStatus = AnswerStatus.CORRECT;
      _timeSpentSeconds = 10 * 60;
      _improvements.updateAll((key, value) => false);
    });
  }

  String _formatTimeSpent(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (seconds == 0) {
      return '$minutes분';
    }

    return '$minutes분 ${seconds.toString().padLeft(2, '0')}초';
  }
}

class _AnswerImagesScreen extends StatefulWidget {
  final List<String> imageUrls;

  const _AnswerImagesScreen({required this.imageUrls});

  @override
  State<_AnswerImagesScreen> createState() => _AnswerImagesScreenState();
}

class _AnswerImagesScreenState extends State<_AnswerImagesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          hasMultiple
              ? '정답 이미지 ${_currentPage + 1} / ${widget.imageUrls.length}'
              : '정답 이미지',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 12),
                    Text(
                      '이미지를 불러오지 못했습니다.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
