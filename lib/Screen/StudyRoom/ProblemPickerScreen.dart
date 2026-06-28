import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../Model/Folder/FolderThumbnailModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Problem/ProblemThumbnailCard.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/NoteIconHandler.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';
import '../../Exception/ApiException.dart';

class ProblemPickerScreen extends StatefulWidget {
  final int roomId;

  const ProblemPickerScreen({super.key, required this.roomId});

  @override
  State<ProblemPickerScreen> createState() => _ProblemPickerScreenState();
}

class _ProblemPickerScreenState extends State<ProblemPickerScreen> {
  List<FolderThumbnailModel> _folders = [];
  int? _selectedFolderId;
  List<ProblemModel> _problems = [];
  int? _problemCursor;
  bool _problemHasNext = false;
  bool _isLoadingFolders = false;
  bool _isLoadingProblems = false;
  bool _isSharing = false;

  late ScrollController _problemScrollController;

  @override
  void initState() {
    super.initState();
    _problemScrollController = ScrollController();
    _problemScrollController.addListener(_onProblemScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFolders());
  }

  @override
  void dispose() {
    _problemScrollController.removeListener(_onProblemScroll);
    _problemScrollController.dispose();
    super.dispose();
  }

  void _onProblemScroll() {
    if (_problemScrollController.position.pixels >=
        _problemScrollController.position.maxScrollExtent * 0.85) {
      if (_problemHasNext && !_isLoadingProblems) _loadMoreProblems();
    }
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoadingFolders = true);
    try {
      final foldersProvider = context.read<FoldersProvider>();
      final response =
          await foldersProvider.folderService.getAllFolderThumbnailsV2(
        cursor: null,
        size: 50,
      );
      if (!mounted) return;
      setState(() {
        _folders = response.content;
        if (_folders.isNotEmpty) {
          _selectedFolderId = _folders.first.folderId;
        }
      });
      if (_selectedFolderId != null) {
        await _loadInitialProblems(_selectedFolderId!);
      }
    } catch (_) {
      if (mounted) AppSnackBar.showError('폴더 목록을 불러오지 못했습니다');
    } finally {
      if (mounted) setState(() => _isLoadingFolders = false);
    }
  }

  Future<void> _loadInitialProblems(int folderId) async {
    setState(() {
      _isLoadingProblems = true;
      _problems = [];
      _problemCursor = null;
      _problemHasNext = false;
    });
    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: folderId,
        cursor: null,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _problems = response.content;
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (_) {
      if (mounted) AppSnackBar.showError('문제 목록을 불러오지 못했습니다');
    } finally {
      if (mounted) setState(() => _isLoadingProblems = false);
    }
  }

  Future<void> _loadMoreProblems() async {
    if (_isLoadingProblems || !_problemHasNext || _selectedFolderId == null) {
      return;
    }
    setState(() => _isLoadingProblems = true);
    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: _selectedFolderId!,
        cursor: _problemCursor,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _problems.addAll(response.content);
        _problemCursor = response.nextCursor;
        _problemHasNext = response.hasNext;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingProblems = false);
    }
  }

  Future<void> _onProblemTap(ProblemModel problem) async {
    if (_isSharing) return;
    final comment = await _showCommentDialog(problem);
    if (comment == null || !mounted) return;
    await _share(problem, comment);
  }

  Future<String?> _showCommentDialog(ProblemModel problem) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final studyRoomProvider =
        Provider.of<StudyRoomProvider>(context, listen: false);
    final controller = TextEditingController();
    final roomName = studyRoomProvider.selectedRoom?.name ?? '선택한 스터디룸';
    final problemTitle = problem.reference?.trim().isNotEmpty == true
        ? problem.reference!
        : '제목 없는 문제';
    try {
      return await showDialog<String>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.ios_share_outlined,
                          color: themeProvider.primaryColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: StandardText(
                          text: '문제를 공유할까요?',
                          fontSize: 17,
                          color: Colors.black87,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 420;
                      final roomTile = _buildShareSummaryRow(
                        icon: Icons.groups_2_outlined,
                        label: '공유할 방',
                        value: roomName,
                        themeProvider: themeProvider,
                      );
                      final problemTile = _buildShareSummaryRow(
                        icon: Icons.assignment_outlined,
                        label: '선택한 문제',
                        value: problemTitle,
                        themeProvider: themeProvider,
                        maxLines: isWide ? 1 : 2,
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            roomTile,
                            const SizedBox(height: 8),
                            problemTile,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: roomTile),
                          const SizedBox(width: 8),
                          Expanded(child: problemTile),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLength: 100,
                    minLines: 2,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '한마디 남기기 (선택)',
                      counterText: '',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[50],
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: StandardText(
                            text: '취소',
                            fontSize: 14,
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          style: TextButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const StandardText(
                            text: '공유하기',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Widget _buildShareSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeHandler themeProvider,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: themeProvider.primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: label,
                  fontSize: 11,
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
                const SizedBox(height: 3),
                StandardText(
                  text: value,
                  fontSize: 13,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(ProblemModel problem, String comment) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      await provider.shareProblems(
        problem.problemId,
        comment: comment.isEmpty ? null : comment,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException) {
        AppSnackBar.showError(error.getUserMessage());
      } else {
        AppSnackBar.showError('문제 공유에 실패했습니다');
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _selectFolder(FolderThumbnailModel folder) {
    if (_selectedFolderId == folder.folderId) return;
    setState(() => _selectedFolderId = folder.folderId);
    _loadInitialProblems(folder.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final roomName = Provider.of<StudyRoomProvider>(context, listen: false)
        .selectedRoom
        ?.name;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const StandardText(
              text: '공유할 문제 선택',
              fontSize: 15,
              color: Colors.black87,
            ),
            if (roomName != null && roomName.isNotEmpty)
              StandardText(
                text: roomName,
                fontSize: 12,
                color: themeProvider.primaryColor,
                fontFamily: 'PretendardLight',
                fontWeight: FontWeight.normal,
              ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: _isLoadingFolders
          ? Center(
              child:
                  CircularProgressIndicator(color: themeProvider.primaryColor))
          : _folders.isEmpty
              ? Center(child: _buildEmptyFolders())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildSplitLayout(themeProvider, constraints);
                  },
                ),
    );
  }

  Widget _buildSplitLayout(
      ThemeHandler themeProvider, BoxConstraints constraints) {
    final folderWidth = max(
      constraints.maxWidth < 360 ? 94.0 : 112.0,
      min(constraints.maxWidth * 0.30, 184.0),
    );
    return Row(
      children: [
        SizedBox(
          width: folderWidth,
          child: _buildSideFolderList(themeProvider),
        ),
        Container(width: 1, color: Colors.grey[200]),
        Expanded(
          child: _buildProblemList(
            themeProvider,
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth < 360 ? 10 : 14,
              12,
              constraints.maxWidth < 360 ? 10 : 14,
              18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideFolderList(ThemeHandler themeProvider) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _folders.length,
        itemBuilder: (_, i) {
          final folder = _folders[i];
          final isSelected = folder.folderId == _selectedFolderId;
          return GestureDetector(
            onTap: () => _selectFolder(folder),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isSelected ? 1.0 : 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeProvider.primaryColor.withValues(alpha: 0.07)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? themeProvider.primaryColor.withValues(alpha: 0.22)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        NoteIconHandler.getNoteIcon(i),
                        width: 42,
                        height: 42,
                      ),
                      const SizedBox(height: 6),
                      StandardText(
                        text: folder.folderName,
                        fontSize: 11,
                        color: isSelected
                            ? themeProvider.primaryColor
                            : Colors.grey[700]!,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                        fontFamily:
                            isSelected ? 'PretendardBold' : 'PretendardLight',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 공통: 문제 목록 ───────────────────────────────────────────────────────

  Widget _buildProblemList(ThemeHandler themeProvider,
      {required EdgeInsets padding}) {
    if (_isLoadingProblems && _problems.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: themeProvider.primaryColor));
    }
    if (_problems.isEmpty) {
      return Center(child: _buildEmptyProblems());
    }
    return ListView.separated(
      controller: _problemScrollController,
      padding: padding,
      itemCount: _problems.length + (_problemHasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == _problems.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                  color: themeProvider.primaryColor, strokeWidth: 2),
            ),
          );
        }
        return _buildProblemCard(_problems[i], themeProvider);
      },
    );
  }

  Widget _buildProblemCard(ProblemModel problem, ThemeHandler themeProvider) {
    final title = problem.reference?.trim().isNotEmpty == true
        ? problem.reference!
        : '제목 없는 문제';
    final imageUrl = problem.problemImageDataList?.firstOrNull?.imageUrl;

    return GestureDetector(
      onTap: () => _onProblemTap(problem),
      child: ProblemThumbnailCard(
        title: title,
        imageUrl: imageUrl,
        tags: problem.tags,
        solveCount: problem.solveCount,
        lastSolvedAt: problem.lastSolvedAt,
        themeProvider: themeProvider,
        trailing: _buildShareTrailing(themeProvider),
      ),
    );
  }

  Widget _buildShareTrailing(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeProvider.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.send_outlined,
              color: themeProvider.primaryColor, size: 16),
          const SizedBox(height: 3),
          StandardText(
            text: '공유',
            fontSize: 10,
            color: themeProvider.primaryColor,
            fontFamily: 'PretendardLight',
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
    );
  }

  // ── 빈 상태 ───────────────────────────────────────────────────────────────

  Widget _buildEmptyFolders() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.folder_open_outlined, size: 52, color: Colors.grey[300]),
        const SizedBox(height: 12),
        StandardText(
          text: '폴더가 없어요',
          fontSize: 15,
          color: Colors.grey[400]!,
        ),
        const SizedBox(height: 4),
        StandardText(
          text: '문제 폴더를 먼저 만들어 보세요',
          fontSize: 13,
          color: Colors.grey[400]!,
          fontWeight: FontWeight.normal,
          fontFamily: 'PretendardLight',
        ),
      ],
    );
  }

  Widget _buildEmptyProblems() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 10),
        StandardText(
          text: '이 폴더에 문제가 없어요',
          fontSize: 14,
          color: Colors.grey[400]!,
        ),
      ],
    );
  }
}
