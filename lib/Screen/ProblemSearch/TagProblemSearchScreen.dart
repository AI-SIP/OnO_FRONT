import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Problem/ProblemThumbnailCard.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';

enum _SearchMode { tag, title }

class TagProblemSearchScreen extends StatefulWidget {
  final bool selectable;
  final List<ProblemModel> initialSelectedProblems;

  const TagProblemSearchScreen({
    super.key,
    this.selectable = false,
    this.initialSelectedProblems = const [],
  });

  @override
  State<TagProblemSearchScreen> createState() => _TagProblemSearchScreenState();
}

class _TagProblemSearchScreenState extends State<TagProblemSearchScreen> {
  final TagService _tagService = TagService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _queryController = TextEditingController();

  _SearchMode _mode = _SearchMode.tag;

  List<TagModel> _tags = [];
  int? _selectedTagId;
  bool _isLoadingTags = false;

  List<ProblemModel> _problems = [];
  int? _cursor;
  bool _hasNext = false;
  bool _isLoadingProblems = false;

  String _currentQuery = '';
  Timer? _debounce;

  final List<ProblemModel> _selectedProblems = [];

  @override
  void initState() {
    super.initState();
    _selectedProblems.addAll(widget.initialSelectedProblems);
    _scrollController.addListener(_onScroll);
    _queryController.addListener(_onQueryChanged);
    _loadTagsAndFirstTagProblems();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _queryController.removeListener(_onQueryChanged);
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProblems();
    }
  }

  void _onQueryChanged() {
    if (_mode != _SearchMode.title) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = _queryController.text.trim();
      if (trimmed == _currentQuery) return;
      _searchByTitle(trimmed, isInitial: true);
    });
  }

  Future<void> _loadTagsAndFirstTagProblems() async {
    setState(() => _isLoadingTags = true);
    try {
      final tags = await _tagService.getMyTags();
      tags.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;

      setState(() {
        _tags = tags;
        if (_tags.isNotEmpty) {
          _selectedTagId = _tags.first.tagId;
        }
      });

      if (_selectedTagId != null && _mode == _SearchMode.tag) {
        await _loadTagProblems(_selectedTagId!, isInitial: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _switchMode(_SearchMode mode) async {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _problems = [];
      _cursor = null;
      _hasNext = false;
      _isLoadingProblems = false;
    });

    if (_mode == _SearchMode.tag && _selectedTagId != null) {
      await _loadTagProblems(_selectedTagId!, isInitial: true);
      return;
    }

    final trimmed = _queryController.text.trim();
    _currentQuery = trimmed;
    if (trimmed.isNotEmpty) {
      await _searchByTitle(trimmed, isInitial: true);
    }
  }

  Future<void> _loadTagProblems(int tagId, {required bool isInitial}) async {
    if (_isLoadingProblems) return;

    if (isInitial) {
      setState(() {
        _selectedTagId = tagId;
        _problems = [];
        _cursor = null;
        _hasNext = false;
        _isLoadingProblems = true;
      });
    } else {
      if (!_hasNext) return;
      setState(() => _isLoadingProblems = true);
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTagProblemsV2(
        tagId: tagId,
        cursor: isInitial ? null : _cursor,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        if (isInitial) {
          _problems = response.content;
        } else {
          _problems.addAll(response.content);
        }
        _cursor = response.nextCursor;
        _hasNext = response.hasNext;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingProblems = false);
      }
    }
  }

  Future<void> _searchByTitle(String query, {required bool isInitial}) async {
    if (_isLoadingProblems) return;

    final trimmed = query.trim();
    _currentQuery = trimmed;

    if (trimmed.isEmpty) {
      setState(() {
        _problems = [];
        _cursor = null;
        _hasNext = false;
        _isLoadingProblems = false;
      });
      return;
    }

    if (isInitial) {
      setState(() {
        _problems = [];
        _cursor = null;
        _hasNext = false;
        _isLoadingProblems = true;
      });
    } else {
      if (!_hasNext) return;
      setState(() => _isLoadingProblems = true);
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTitleProblemsV2(
        query: trimmed,
        cursor: isInitial ? null : _cursor,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        if (isInitial) {
          _problems = response.content;
        } else {
          _problems.addAll(response.content);
        }
        _cursor = response.nextCursor;
        _hasNext = response.hasNext;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingProblems = false);
      }
    }
  }

  Future<void> _loadMoreProblems() async {
    if (_isLoadingProblems || !_hasNext) return;

    if (_mode == _SearchMode.tag && _selectedTagId != null) {
      await _loadTagProblems(_selectedTagId!, isInitial: false);
      return;
    }

    if (_mode == _SearchMode.title && _currentQuery.isNotEmpty) {
      await _searchByTitle(_currentQuery, isInitial: false);
    }
  }

  void _toggleProblemSelection(ProblemModel problem) {
    final index =
        _selectedProblems.indexWhere((p) => p.problemId == problem.problemId);
    setState(() {
      if (index >= 0) {
        _selectedProblems.removeAt(index);
      } else {
        _selectedProblems.add(problem);
      }
    });
  }

  bool _isSelected(ProblemModel problem) {
    return _selectedProblems.any((p) => p.problemId == problem.problemId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeHandler>();
    final baseTextStyle = const StandardText(text: '').getTextStyle();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '오답노트 검색',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          _buildModeSelector(themeProvider),
          if (_mode == _SearchMode.tag)
            _buildTagFilterBar(themeProvider)
          else
            _buildTitleSearchBar(themeProvider, baseTextStyle),
          Expanded(
            child: _buildProblemList(themeProvider),
          ),
          if (widget.selectable) _buildBottomConfirmButton(themeProvider),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeHandler themeProvider) {
    Widget modeChip({
      required _SearchMode mode,
      required String label,
    }) {
      final selected = _mode == mode;
      return Expanded(
        child: InkWell(
          onTap: () => _switchMode(mode),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? themeProvider.primaryColor.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    selected ? themeProvider.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: StandardText(
              text: label,
              fontSize: 13,
              color: selected ? themeProvider.primaryColor : Colors.grey[700]!,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          modeChip(mode: _SearchMode.tag, label: '태그로 검색'),
          const SizedBox(width: 8),
          modeChip(mode: _SearchMode.title, label: '제목으로 검색'),
        ],
      ),
    );
  }

  Widget _buildTitleSearchBar(
      ThemeHandler themeProvider, TextStyle baseTextStyle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: TextField(
        controller: _queryController,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _searchByTitle(value.trim(), isInitial: true),
        style: baseTextStyle.copyWith(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '제목으로 검색 (예: 수특)',
          hintStyle: baseTextStyle.copyWith(
            color: Colors.grey[500],
            fontSize: 13,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: themeProvider.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilterBar(ThemeHandler themeProvider) {
    if (_isLoadingTags) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CircularProgressIndicator(),
      );
    }

    if (_tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: StandardText(
            text: '생성된 태그가 없습니다.',
            fontSize: 13,
            color: Colors.grey[600]!,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tags.map((tag) {
            final selected = tag.tagId == _selectedTagId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _loadTagProblems(tag.tagId, isInitial: true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? themeProvider.primaryColor.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? themeProvider.primaryColor
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: StandardText(
                    text: '#${tag.name}',
                    fontSize: 12,
                    color: selected
                        ? themeProvider.primaryColor
                        : Colors.grey[700]!,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProblemList(ThemeHandler themeProvider) {
    if (_isLoadingProblems && _problems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_problems.isEmpty) {
      if (_mode == _SearchMode.title && _currentQuery.isEmpty) {
        return const Center(
          child: StandardText(
            text: '검색어를 입력해주세요.',
            fontSize: 15,
            color: Colors.black,
          ),
        );
      }
      final emptyText =
          _mode == _SearchMode.tag ? '해당 태그의 오답노트가 없습니다.' : '검색 결과가 없습니다.';
      return _buildEmptyState(emptyText);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: _problems.length + (_hasNext || _isLoadingProblems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _problems.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final problem = _problems[index];
        return _buildProblemTile(problem, themeProvider);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/Icon/PencilDetail.svg',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  StandardText(
                    text: message,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    final problemImageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;
    final isSelected = _isSelected(problem);
    final title =
        problem.reference?.isNotEmpty == true ? problem.reference! : '제목 없음';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          if (widget.selectable) {
            _toggleProblemSelection(problem);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProblemDetailScreen(problemId: problem.problemId),
            ),
          );
        },
        child: ProblemThumbnailCard(
          title: title,
          imageUrl: problemImageUrl,
          tags: problem.tags,
          solveCount: problem.solveCount,
          lastSolvedAt: problem.lastSolvedAt,
          themeProvider: themeProvider,
          titleFontSize: isMobile ? 15 : 16,
          tagFontSize: isMobile ? 9 : 10,
          tagPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 2 : 3,
          ),
          trailing: widget.selectable
              ? Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? themeProvider.primaryColor
                      : Colors.grey[400],
                  size: 22,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBottomConfirmButton(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      width: MediaQuery.of(context).size.width * 0.7,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context, List<ProblemModel>.from(_selectedProblems));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: Center(
                child: StandardText(
                  text: '선택 완료',
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: StandardText(
                text: _selectedProblems.length.toString(),
                fontSize: 12,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
