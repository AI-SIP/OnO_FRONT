import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Folder/FolderThumbnailModel.dart';
import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
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
  String _selectedFolderName = '';
  List<ProblemModel> _problems = [];
  int? _problemCursor;
  bool _problemHasNext = false;
  bool _isLoadingFolders = false;
  bool _isLoadingProblems = false;
  bool _isSharing = false;

  late ScrollController _problemScrollController;
  final ScrollController _chipScrollController = ScrollController();

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
    _chipScrollController.dispose();
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
          _selectedFolderName = _folders.first.folderName;
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
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const StandardText(
          text: '문제를 공유할까요?',
          fontSize: 15,
          color: Colors.black87,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShareSummaryRow(
                icon: Icons.groups_2_outlined,
                label: '공유할 방',
                value: roomName,
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 10),
              _buildShareSummaryRow(
                icon: Icons.assignment_outlined,
                label: '선택한 문제',
                value: problemTitle,
                themeProvider: themeProvider,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 100,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '한마디 남기기 (선택)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('취소', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('공유하기',
                style: TextStyle(
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(10),
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
    setState(() {
      _selectedFolderId = folder.folderId;
      _selectedFolderName = folder.folderName;
    });
    _loadInitialProblems(folder.folderId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const StandardText(
          text: '공유할 문제 선택',
          fontSize: 16,
          color: Colors.black87,
        ),
        centerTitle: true,
      ),
      body: _isLoadingFolders
          ? Center(
              child:
                  CircularProgressIndicator(color: themeProvider.primaryColor))
          : _folders.isEmpty
              ? Center(child: _buildEmptyFolders())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      return _buildWideLayout(themeProvider, constraints);
                    } else {
                      return _buildNarrowLayout(themeProvider);
                    }
                  },
                ),
    );
  }

  // ── 태블릿 / 가로 폰: 좌측 폴더 패널 + 우측 문제 목록 ──────────────────

  Widget _buildWideLayout(
      ThemeHandler themeProvider, BoxConstraints constraints) {
    final folderWidth = max(120.0, constraints.maxWidth * 0.28);
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSideFolderList(ThemeHandler themeProvider) {
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (_, i) {
          final folder = _folders[i];
          final isSelected = folder.folderId == _selectedFolderId;
          return GestureDetector(
            onTap: () => _selectFolder(folder),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: Row(
                children: [
                  if (isSelected)
                    Container(
                      width: 3,
                      height: 14,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Expanded(
                    child: StandardText(
                      text: folder.folderName,
                      fontSize: 13,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : Colors.black54,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontFamily:
                          isSelected ? 'PretendardBold' : 'PretendardLight',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 세로 폰: 상단 칩 + 하단 문제 목록 ────────────────────────────────────

  Widget _buildNarrowLayout(ThemeHandler themeProvider) {
    return Column(
      children: [
        _buildFolderChips(themeProvider),
        Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        Expanded(
          child: _buildProblemList(
            themeProvider,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderChips(ThemeHandler themeProvider) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        controller: _chipScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _folders.length,
        itemBuilder: (_, i) {
          final folder = _folders[i];
          final isSelected = folder.folderId == _selectedFolderId;
          return GestureDetector(
            onTap: () => _selectFolder(folder),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? themeProvider.primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: StandardText(
                text: folder.folderName,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontFamily: isSelected ? 'PretendardBold' : 'PretendardLight',
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final primary = themeProvider.primaryColor;
    final firstImage = problem.problemImageDataList?.firstOrNull;

    return GestureDetector(
      onTap: () => _onProblemTap(problem),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 60,
                height: 72,
                child: firstImage?.imageUrl != null
                    ? Image.network(
                        firstImage!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(primary),
                      )
                    : _imagePlaceholder(primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (problem.reference != null &&
                      problem.reference!.isNotEmpty)
                    StandardText(
                      text: problem.reference!,
                      fontSize: 14,
                      color: Colors.black87,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: StandardText(
                      text: _selectedFolderName,
                      fontSize: 11,
                      color: primary,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'PretendardLight',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child:
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Color primary) {
    return Container(
      color: primary.withValues(alpha: 0.06),
      child: Icon(
        Icons.assignment_outlined,
        color: primary.withValues(alpha: 0.4),
        size: 28,
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
