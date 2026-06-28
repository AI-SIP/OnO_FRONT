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
    final comment = await _showCommentDialog(problem);
    if (comment == null || !mounted) return;
    await _share(problem, comment);
  }

  Future<String?> _showCommentDialog(ProblemModel problem) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const StandardText(
          text: '이 문제를 공유할까요?',
          fontSize: 15,
          color: Colors.black87,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (problem.reference != null && problem.reference!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StandardText(
                  text: problem.reference!,
                  fontSize: 13,
                  color: Colors.grey[600]!,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
              ),
            TextField(
              controller: controller,
              maxLength: 100,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '한마디 코멘트 (선택)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
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

  Future<void> _share(ProblemModel problem, String comment) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final provider =
          Provider.of<StudyRoomProvider>(context, listen: false);
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
              child: CircularProgressIndicator(
                  color: themeProvider.primaryColor))
          : _folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      StandardText(
                        text: '등록된 폴더가 없어요',
                        fontSize: 15,
                        color: Colors.grey[500]!,
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    _buildFolderList(themeProvider),
                    Container(width: 1, color: Colors.grey[200]),
                    Expanded(child: _buildProblemList(themeProvider)),
                  ],
                ),
    );
  }

  Widget _buildFolderList(ThemeHandler themeProvider) {
    return SizedBox(
      width: 110,
      child: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (_, i) {
          final folder = _folders[i];
          final isSelected = folder.folderId == _selectedFolderId;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() {
                _selectedFolderId = folder.folderId;
                _selectedFolderName = folder.folderName;
              });
              _loadInitialProblems(folder.folderId);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              color: isSelected
                  ? themeProvider.primaryColor.withValues(alpha: 0.07)
                  : Colors.white,
              child: Row(
                children: [
                  if (isSelected)
                    Container(
                      width: 3,
                      height: 14,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Expanded(
                    child: StandardText(
                      text: folder.folderName,
                      fontSize: 12,
                      color: isSelected
                          ? themeProvider.primaryColor
                          : Colors.black54,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
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

  Widget _buildProblemList(ThemeHandler themeProvider) {
    if (_isLoadingProblems && _problems.isEmpty) {
      return Center(
          child: CircularProgressIndicator(color: themeProvider.primaryColor));
    }
    if (_problems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            StandardText(
              text: '문제가 없어요',
              fontSize: 14,
              color: Colors.grey[500]!,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _problemScrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
        final problem = _problems[i];
        return _buildProblemCard(problem, themeProvider);
      },
    );
  }

  Widget _buildProblemCard(ProblemModel problem, ThemeHandler themeProvider) {
    final primary = themeProvider.primaryColor;
    final firstImage = problem.problemImageDataList?.firstOrNull;

    return GestureDetector(
      onTap: () => _onProblemTap(problem),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 64,
                color: primary.withValues(alpha: 0.07),
                child: firstImage?.imageUrl != null
                    ? Image.network(
                        firstImage!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image_not_supported_outlined,
                                color: Colors.grey[400], size: 22),
                      )
                    : Icon(Icons.assignment_outlined,
                        color: primary.withValues(alpha: 0.5), size: 26),
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
                      fontSize: 13,
                      color: Colors.black87,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  const SizedBox(height: 4),
                  StandardText(
                    text: _selectedFolderName,
                    fontSize: 11,
                    color: Colors.grey[500]!,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'PretendardLight',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
