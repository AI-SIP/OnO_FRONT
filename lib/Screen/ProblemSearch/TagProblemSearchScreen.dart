import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';

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

  List<TagModel> _tags = [];
  int? _selectedTagId;

  List<ProblemModel> _problems = [];
  int? _cursor;
  bool _hasNext = false;
  bool _isLoadingTags = false;
  bool _isLoadingProblems = false;

  final List<ProblemModel> _selectedProblems = [];

  @override
  void initState() {
    super.initState();
    _selectedProblems.addAll(widget.initialSelectedProblems);
    _scrollController.addListener(_onScroll);
    _loadTags();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreProblems();
    }
  }

  Future<void> _loadTags() async {
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
      if (_selectedTagId != null) {
        await _loadInitialProblems(_selectedTagId!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTags = false);
      }
    }
  }

  Future<void> _loadInitialProblems(int tagId) async {
    setState(() {
      _selectedTagId = tagId;
      _problems = [];
      _cursor = null;
      _hasNext = false;
      _isLoadingProblems = true;
    });

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTagProblemsV2(
        tagId: tagId,
        cursor: null,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _problems = response.content;
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
    if (_isLoadingProblems || !_hasNext || _selectedTagId == null) return;

    setState(() => _isLoadingProblems = true);
    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTagProblemsV2(
        tagId: _selectedTagId!,
        cursor: _cursor,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _problems.addAll(response.content);
        _cursor = response.nextCursor;
        _hasNext = response.hasNext;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingProblems = false);
      }
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: '태그로 문제 검색',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: Column(
        children: [
          _buildTagFilterBar(themeProvider),
          Expanded(
            child: _buildProblemList(themeProvider),
          ),
          if (widget.selectable) _buildBottomConfirmButton(themeProvider),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tags.map((tag) {
            final selected = tag.tagId == _selectedTagId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _loadInitialProblems(tag.tagId),
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
      return Center(
        child: StandardText(
          text: '해당 태그의 문제가 없습니다.',
          fontSize: 15,
          color: Colors.grey[600]!,
        ),
      );
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

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    final problemImageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;
    final isSelected = _isSelected(problem);

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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 70,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.selectable && isSelected
                      ? Icon(Icons.check, color: themeProvider.primaryColor)
                      : DisplayImage(
                          imagePath: problemImageUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StandardText(
                      text: (problem.reference != null &&
                              problem.reference!.isNotEmpty)
                          ? problem.reference!
                          : '제목 없음',
                      color: Colors.black,
                      fontSize: 17,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: problem.tags.isNotEmpty
                          ? problem.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeProvider.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: StandardText(
                                  text: '#${tag.name}',
                                  fontSize: 11,
                                  color: themeProvider.primaryColor,
                                ),
                              );
                            }).toList()
                          : [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: StandardText(
                                  text: '태그 없음',
                                  fontSize: 11,
                                  color: Colors.grey[400]!,
                                ),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
              if (widget.selectable)
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? themeProvider.primaryColor
                      : Colors.grey[400],
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomConfirmButton(ThemeHandler themeProvider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(
                  context, List<ProblemModel>.from(_selectedProblems));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const StandardText(
                  text: '선택 완료',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: StandardText(
                    text: _selectedProblems.length.toString(),
                    color: themeProvider.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
