import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Tag/TagModel.dart';
import '../../Module/Problem/ProblemThumbnailCard.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ClayIcon.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Service/Api/Tag/TagService.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import '../../Module/Motion/AppMotion.dart';
import '../../Module/Motion/AppearTransition.dart';
import '../../Module/Motion/AppHaptic.dart';
import '../../Module/Motion/PressableScale.dart';
import '../../Module/Motion/Skeleton.dart';
import '../../Module/Motion/TossPageRoute.dart';
import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Util/AppAnalytics.dart';
import '../../Util/AppErrorReporter.dart';
import '../../Util/PendingDeletion.dart';
import '../../Provider/FoldersProvider.dart';

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

  // 제목으로 찾는 사람이 더 많아서 제목 검색을 먼저 연다.
  _SearchMode _mode = _SearchMode.title;

  List<TagModel> _tags = [];
  int? _selectedTagId;
  bool _isLoadingTags = false;

  List<ProblemModel> _problems = [];
  int? _cursor;
  bool _hasNext = false;
  bool _isLoadingProblems = false;

  /// 마지막 조회가 실패했는지. 실패를 결과 없음과 구분해 다시 시도를 보인다.
  bool _loadFailed = false;

  String _currentQuery = '';
  Timer? _debounce;

  final List<ProblemModel> _selectedProblems = [];

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView('TagProblemSearchScreen');
    _selectedProblems.addAll(widget.initialSelectedProblems);
    _scrollController.addListener(_onScroll);
    _queryController.addListener(_onQueryChanged);
    PendingDeletion.instance.addListener(_onPendingDeletionChanged);
    _loadTagsAndFirstTagProblems();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    PendingDeletion.instance.removeListener(_onPendingDeletionChanged);
    _scrollController.removeListener(_onScroll);
    _queryController.removeListener(_onQueryChanged);
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onPendingDeletionChanged() {
    if (mounted) setState(() {});
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
    } catch (e, stackTrace) {
      _onLoadFailed(e, stackTrace);
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
      _loadFailed = false;
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
        _loadFailed = false;
      });
    } else {
      if (!_hasNext) return;
      setState(() {
        _isLoadingProblems = true;
        _loadFailed = false;
      });
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTagProblemsV2(
        tagId: tagId,
        cursor: isInitial ? null : _cursor,
        size: 20,
      );
      if (isInitial) {
        // 검색어는 보내지 않는다. 무엇으로 찾고 몇 개가 나오는지만 본다.
        AppAnalytics.logEvent('problem_search', {
          'mode': 'tag',
          'result_count': response.content.length,
          'has_next': response.hasNext,
        });
      }
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
    } catch (e, stackTrace) {
      // 예전에는 catch 가 없어서 실패해도 결과가 없는 것처럼 보였고, 입력
      // 디바운스 타이머 안에서 난 예외는 아무도 받지 않았다.
      _onLoadFailed(e, stackTrace);
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
        _loadFailed = false;
      });
    } else {
      if (!_hasNext) return;
      setState(() {
        _isLoadingProblems = true;
        _loadFailed = false;
      });
    }

    try {
      final problemsProvider = context.read<ProblemsProvider>();
      final response = await problemsProvider.loadMoreTitleProblemsV2(
        query: trimmed,
        cursor: isInitial ? null : _cursor,
        size: 20,
      );
      if (isInitial) {
        // 검색어는 보내지 않는다. 무엇으로 찾고 몇 개가 나오는지만 본다.
        AppAnalytics.logEvent('problem_search', {
          'mode': 'title',
          'result_count': response.content.length,
          'has_next': response.hasNext,
        });
      }
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
    } catch (e, stackTrace) {
      // 예전에는 catch 가 없어서 실패해도 결과가 없는 것처럼 보였고, 입력
      // 디바운스 타이머 안에서 난 예외는 아무도 받지 않았다.
      _onLoadFailed(e, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoadingProblems = false);
      }
    }
  }

  void _onLoadFailed(Object error, StackTrace stackTrace) {
    debugPrint('검색 결과를 불러오지 못했습니다: $error');
    unawaited(AppErrorReporter.report(
      error,
      stackTrace,
      source: 'problem_search_load',
      severity: AppErrorSeverity.warning,
    ));
    if (mounted) setState(() => _loadFailed = true);
  }

  /// 실패한 조회를 다시 한다. 받아 둔 결과가 있으면 다음 쪽부터 다시 받는다.
  Future<void> _retryLoad() async {
    final isInitial = _problems.isEmpty;
    if (_mode == _SearchMode.tag && _tags.isEmpty) {
      setState(() => _loadFailed = false);
      await _loadTagsAndFirstTagProblems();
      return;
    }
    if (_mode == _SearchMode.tag && _selectedTagId != null) {
      await _loadTagProblems(_selectedTagId!, isInitial: isInitial);
      return;
    }
    await _searchByTitle(_currentQuery, isInitial: isInitial);
  }

  Future<void> _loadMoreProblems() async {
    // 다음 쪽을 받다 실패했으면 스크롤할 때마다 다시 부르지 않고 버튼을 기다린다.
    if (_isLoadingProblems || !_hasNext || _loadFailed) return;

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
      required IconData icon,
    }) {
      final selected = _mode == mode;
      return Expanded(
        child: PressableScale(
          haptic: HapticLevel.selection,
          onTap: () => _switchMode(mode),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? themeProvider.primaryColor.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color:
                    selected ? themeProvider.primaryColor : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color:
                      selected ? themeProvider.primaryColor : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                StandardText(
                  text: label,
                  fontSize: 13,
                  color:
                      selected ? themeProvider.primaryColor : Colors.grey[700]!,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          modeChip(
            mode: _SearchMode.title,
            label: '제목으로 검색',
            icon: Icons.search_rounded,
          ),
          const SizedBox(width: 8),
          modeChip(
            mode: _SearchMode.tag,
            label: '태그로 검색',
            icon: Icons.sell_outlined,
          ),
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
        // 검색하러 들어왔으니 바로 쓸 수 있게 한다. 복습 세트에 넣을 문제를
        // 고르는 화면에서는 키보드가 목록을 가려서 띄우지 않는다.
        autofocus: !widget.selectable,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => _searchByTitle(value.trim(), isInitial: true),
        style: baseTextStyle.copyWith(
          fontSize: 14,
          color: AppColors.textPrimary,
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
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
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
        padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: SkeletonBox(height: 34, borderRadius: 17),
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
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: StandardText(
            text: '생성된 태그가 없어요.',
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
              child: PressableScale(
                haptic: HapticLevel.selection,
                onTap: () => _loadTagProblems(tag.tagId, isInitial: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? themeProvider.primaryColor.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.small),
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

  /// 검색 결과에서 하나씩 들어오게 할 항목 수.
  static const int _staggeredItemLimit = 8;

  Widget _buildProblemList(ThemeHandler themeProvider) {
    // 지우고 되돌리기를 기다리는 문제는 빼고 그린다. 전에는 상세에서 지우고
    // 돌아와도 검색 결과에 그대로 남아 있었다.
    final pending = PendingDeletion.instance;
    final problems =
        _problems.where((p) => !pending.isProblemHidden(p.problemId)).toList();

    if (_isLoadingProblems && problems.isEmpty) {
      return const SkeletonList(
        itemCount: 5,
        itemHeight: 88,
        spacing: 12,
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
      );
    }

    if (problems.isEmpty && _loadFailed) {
      return _buildEmptyState(
        '오답노트를 불러오지 못했어요',
        detail: '인터넷 연결을 확인하고 다시 시도해 주세요.',
        action: _buildRetryButton(themeProvider),
      );
    }

    if (problems.isEmpty) {
      if (_mode == _SearchMode.title && _currentQuery.isEmpty) {
        // 문구만 덩그러니 있으면 화면이 비어 보인다. 다른 빈 화면처럼
        // 그림을 두되, 검색 안내라 연필 대신 돋보기를 쓴다. 둘 다 같은 손으로
        // 빚은 점토 그림이라 나란히 놓아도 결이 맞는다.
        return _buildEmptyState(
          '검색어를 입력해 주세요.',
          iconAsset: 'assets/Icon/Search.png',
          detail: '오답노트 제목의 일부만 넣어도 찾을 수 있어요.',
        );
      }
      final emptyText =
          _mode == _SearchMode.tag ? '해당 태그의 오답노트가 없어요.' : '검색 결과가 없어요.';
      return _buildEmptyState(emptyText);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: problems.length + (_hasNext || _isLoadingProblems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == problems.length) {
          if (_loadFailed && !_isLoadingProblems) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: _buildRetryButton(themeProvider)),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final problem = problems[index];
        // 검색 결과가 툭 나타나지 않고 하나씩 들어온다.
        return AppearTransition(
          enabled: index < _staggeredItemLimit,
          delay: AppMotion.stagger * index,
          child: _buildProblemTile(problem, themeProvider),
        );
      },
    );
  }

  /// [iconAsset] 을 주면 기본 연필 대신 그 그림을 그린다. [detail] 은 그 아래
  /// 덧붙이는 한 줄이다.
  Widget _buildRetryButton(ThemeHandler themeProvider) {
    return OutlinedButton(
      onPressed: _retryLoad,
      style: OutlinedButton.styleFrom(
        foregroundColor: themeProvider.primaryColor,
        side: BorderSide(
            color: themeProvider.primaryColor.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      child: StandardText(
        text: '다시 시도',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(
    String message, {
    String? iconAsset,
    String? detail,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: AppearTransition(
              offset: 12,
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClayIcon(
                      iconAsset ?? 'assets/Icon/PencilDetail.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 16),
                    StandardText(
                      text: message,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 6),
                      StandardText(
                        text: detail,
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 18),
                      action,
                    ],
                  ],
                ),
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
          AppAnalytics.logEvent('search_result_open', {'mode': _mode.name});
          await Navigator.push(
            context,
            TossPageRoute(
              builder: (_) => ProblemDetailScreen(problemId: problem.problemId),
            ),
          );
          // 상세에서 복습하거나 고친 값으로 카드를 바꾼다. 전에는 돌아와도
          // 들어가기 전 모습 그대로였다.
          if (!mounted) return;
          final latest = Provider.of<ProblemsProvider>(context, listen: false)
              .cachedProblem(problem.problemId);
          final index =
              _problems.indexWhere((p) => p.problemId == problem.problemId);
          if (latest != null && index >= 0) {
            setState(() => _problems[index] = latest);
          }
        },
        child: ProblemThumbnailCard(
          title: title,
          subtitle: problem.folderId == null
              ? null
              : Provider.of<FoldersProvider>(context, listen: false)
                  .folderNameOf(problem.folderId!),
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
            borderRadius: BorderRadius.circular(AppRadius.large),
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
