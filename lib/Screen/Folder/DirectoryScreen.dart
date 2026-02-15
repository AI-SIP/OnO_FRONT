import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/Common/LoginStatus.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Model/Problem/ProblemRegisterModel.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:ono/Module/Theme/NoteIconHandler.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemThumbnailModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Image/DisplayImage.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerDialog.dart';
import '../../Provider/UserProvider.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import '../ProblemRegister/ProblemRegisterScreen.dart';
import 'UserGuideScreen.dart';

class DirectoryScreen extends StatefulWidget {
  final int? folderId; // 이 화면이 표시할 폴더 ID

  const DirectoryScreen({super.key, this.folderId});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  static const double _dialogMaxWidth = 420;
  bool modalShown = false;
  bool _isSelectionMode = false; // 선택 모드 활성화 여부
  final List<int> _selectedFolderIds = []; // 선택된 폴더 ID 리스트
  final List<int> _selectedProblemIds = []; // 선택된 문제 ID 리스트
  FolderModel? _currentFolder; // 이 화면의 폴더 데이터

  // 로컬 상태: 이 화면만의 하위 폴더와 문제 리스트
  List<FolderThumbnailModel> _localSubfolders = [];
  List<ProblemModel> _localProblems = [];

  // 로컬 무한 스크롤 상태
  int? _subfolderNextCursor;
  int? _problemNextCursor;
  bool _subfolderHasNext = false;
  bool _problemHasNext = false;
  bool _isLoadingSubfolders = false;
  bool _isLoadingProblems = false;

  // 초기 로딩 상태 (폴더 진입 시)
  bool _isInitialLoading = false;

  // 무한 스크롤을 위한 ScrollController
  late ScrollController _scrollController;

  // 루트 폴더 새로고침 타임스탬프 추적
  int _lastRootFolderRefreshTimestamp = 0;

  // 새로고침 중복 실행 방지
  bool _isRefreshing = false;
  bool _isQuickCreateOpen = false;

  @override
  void initState() {
    super.initState();
    _isSelectionMode = false; // 선택 모드 활성화 여부

    // ScrollController 초기화
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 이 화면의 폴더 데이터 로드
      await _loadFolderData();

      if (!modalShown && userProvider.isFirstLogin && widget.folderId == null) {
        modalShown = true;
        userProvider.changeIsFirstLogin();
        _showUserGuideModal();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DirectoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // folderId가 변경되면 데이터 다시 로드
    if (oldWidget.folderId != widget.folderId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadFolderData();
      });
    }
  }

  // 스크롤 이벤트 리스너 (로컬 무한 스크롤)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (_currentFolder == null) return;

      // 80% 스크롤 시 로컬 데이터 더 로드
      if (_subfolderHasNext && !_isLoadingSubfolders) {
        _loadMoreSubfoldersLocal(_currentFolder!.folderId);
      }
      if (_problemHasNext && !_isLoadingProblems) {
        _loadMoreProblemsLocal(_currentFolder!.folderId);
      }
    }
  }

  Future<void> _loadFolderData() async {
    // 초기 로딩 상태 시작
    if (mounted) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    // 이 화면의 폴더 ID 결정
    int targetFolderId;
    if (widget.folderId == null) {
      // 루트 폴더
      if (foldersProvider.rootFolder == null) {
        await foldersProvider.fetchRootFolder();
      }
      targetFolderId = foldersProvider.rootFolder!.folderId;
    } else {
      targetFolderId = widget.folderId!;
    }

    // 폴더 메타데이터만 가져오기 (Provider의 currentFolder는 업데이트하지 않음)
    final folder = await foldersProvider.getFolder(targetFolderId);

    // 로컬 상태 초기화
    if (mounted) {
      setState(() {
        _currentFolder = folder;
        _localSubfolders = [];
        _localProblems = [];
        _subfolderNextCursor = null;
        _problemNextCursor = null;
        _subfolderHasNext = false;
        _problemHasNext = false;
      });
    }

    try {
      // 첫 페이지 로드 (하위 폴더와 문제) - 캐시 우선 사용
      await Future.wait([
        _loadMoreSubfoldersLocal(targetFolderId),
        _loadMoreProblemsLocal(targetFolderId),
      ]);
    } finally {
      // 초기 로딩 완료
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  // 로컬 하위 폴더 로드 (캐시 우선 사용)
  Future<void> _loadMoreSubfoldersLocal(int folderId) async {
    if (_isLoadingSubfolders) return;
    if (!_subfolderHasNext && _subfolderNextCursor != null) return;

    if (!mounted) return;

    setState(() {
      _isLoadingSubfolders = true;
    });

    try {
      final foldersProvider =
          Provider.of<FoldersProvider>(context, listen: false);

      // 캐시 존재 여부 확인 (빈 리스트도 유효한 캐시)
      final hasCachedData = foldersProvider.hasSubfolderCache(folderId);

      // 캐시가 존재하고, 첫 로드인 경우 캐시 사용
      if (_subfolderNextCursor == null && hasCachedData) {
        final cachedSubfolders =
            foldersProvider.getSubfoldersForFolder(folderId);
        final cachedHasNext =
            foldersProvider.getSubfolderHasNextForFolder(folderId);

        log('✅ Using cached subfolders for folder $folderId (${cachedSubfolders.length} items)');
        if (mounted) {
          setState(() {
            _localSubfolders.addAll(cachedSubfolders);
            // Provider의 상태 복사
            _subfolderNextCursor = cachedSubfolders.isNotEmpty
                ? cachedSubfolders.last.folderId
                : null;
            _subfolderHasNext = cachedHasNext;
            _isLoadingSubfolders = false; // 캐시 사용 시 여기서 로딩 상태 해제
          });
        }
        return;
      }

      // 캐시에 없는 경우 서버 요청
      log('📡 Fetching subfolders from server for folder $folderId (cursor: $_subfolderNextCursor)');

      // 서버에서 직접 조회
      final response = await foldersProvider.folderService.getSubfoldersV2(
        folderId: folderId,
        cursor: _subfolderNextCursor,
        size: 20,
      );

      // 로컬 상태 업데이트 (모든 페이지)
      if (mounted) {
        setState(() {
          _localSubfolders.addAll(response.content);
          _subfolderNextCursor = response.nextCursor;
          _subfolderHasNext = response.hasNext;
        });
      }

      // Provider 캐시에 누적 저장 (모든 페이지를 누적해서 저장)
      await _appendSubfoldersToProviderCache(
          folderId,
          _localSubfolders, // 누적된 전체 데이터 저장
          response.nextCursor,
          response.hasNext);
      log('💾 Saved total ${_localSubfolders.length} subfolders to cache for folder $folderId');

      log('Loaded ${response.content.length} subfolders from server for folder $folderId');
    } catch (e, stackTrace) {
      log('Error loading subfolders locally: $e');
      log(stackTrace.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubfolders = false;
        });
      }
    }
  }

  // Provider 캐시에 하위 폴더 저장 (첫 페이지용)
  Future<void> _saveSubfoldersToProviderCache(
    int folderId,
    List<FolderThumbnailModel> subfolders,
    int? nextCursor,
    bool hasNext,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    foldersProvider.saveSubfoldersToCache(
        folderId, subfolders, nextCursor, hasNext);
  }

  // Provider 캐시에 하위 폴더 누적 저장 (모든 페이지용)
  Future<void> _appendSubfoldersToProviderCache(
    int folderId,
    List<FolderThumbnailModel> allSubfolders,
    int? nextCursor,
    bool hasNext,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    foldersProvider.saveSubfoldersToCache(
        folderId, allSubfolders, nextCursor, hasNext);
  }

  // Provider 캐시에 문제 저장 (첫 페이지용)
  Future<void> _saveProblemsToProviderCache(
    int folderId,
    List<ProblemModel> problems,
    int? nextCursor,
    bool hasNext,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    foldersProvider.saveProblemsToCache(
        folderId, problems, nextCursor, hasNext);
  }

  // Provider 캐시에 문제 누적 저장 (모든 페이지용)
  Future<void> _appendProblemsToProviderCache(
    int folderId,
    List<ProblemModel> allProblems,
    int? nextCursor,
    bool hasNext,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    foldersProvider.saveProblemsToCache(
        folderId, allProblems, nextCursor, hasNext);
  }

  // 로컬 문제 로드 (캐시 우선 사용)
  Future<void> _loadMoreProblemsLocal(int folderId) async {
    if (_isLoadingProblems) return;
    if (!_problemHasNext && _problemNextCursor != null) return;

    if (!mounted) return;

    setState(() {
      _isLoadingProblems = true;
    });

    try {
      final foldersProvider =
          Provider.of<FoldersProvider>(context, listen: false);

      // 캐시 존재 여부 확인 (빈 리스트도 유효한 캐시)
      final hasCachedData = foldersProvider.hasProblemCache(folderId);

      // 캐시가 존재하고, 첫 로드인 경우 캐시 사용
      if (_problemNextCursor == null && hasCachedData) {
        final cachedProblems = foldersProvider.getProblemsForFolder(folderId);
        final cachedHasNext =
            foldersProvider.getProblemHasNextForFolder(folderId);

        log('✅ Using cached problems for folder $folderId (${cachedProblems.length} items)');
        if (mounted) {
          setState(() {
            _localProblems.addAll(cachedProblems);
            // Provider의 상태 복사
            _problemNextCursor = cachedProblems.isNotEmpty
                ? cachedProblems.last.problemId
                : null;
            _problemHasNext = cachedHasNext;
            _isLoadingProblems = false; // 캐시 사용 시 여기서 로딩 상태 해제
          });
        }
        return;
      }

      // 캐시에 없는 경우 서버 요청
      log('📡 Fetching problems from server for folder $folderId (cursor: $_problemNextCursor)');
      final problemsProvider =
          Provider.of<ProblemsProvider>(context, listen: false);
      final response = await problemsProvider.loadMoreFolderProblemsV2(
        folderId: folderId,
        cursor: _problemNextCursor,
        size: 20,
      );

      // 로컬 상태 업데이트 (모든 페이지)
      if (mounted) {
        setState(() {
          _localProblems.addAll(response.content);
          _problemNextCursor = response.nextCursor;
          _problemHasNext = response.hasNext;
        });
      }

      // Provider 캐시에 누적 저장 (모든 페이지를 누적해서 저장)
      await _appendProblemsToProviderCache(
          folderId,
          _localProblems, // 누적된 전체 데이터 저장
          response.nextCursor,
          response.hasNext);
      log('💾 Saved total ${_localProblems.length} problems to cache for folder $folderId');

      log('Loaded ${response.content.length} problems from server for folder $folderId');
    } catch (e, stackTrace) {
      log('Error loading problems locally: $e');
      log(stackTrace.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProblems = false;
        });
      }
    }
  }

  void _showUserGuideModal() async {
    FirebaseAnalytics.instance.logEvent(name: 'show_user_guide_modal');

    final openTime = DateTime.now();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 스크롤 가능 모달 설정
      backgroundColor: Colors.transparent, // 투명 배경
      isDismissible: false,
      builder: (BuildContext context) {
        return TapRegion(
            onTapOutside: (_) {
              // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
              if (DateTime.now().difference(openTime) <
                  const Duration(milliseconds: 500)) {
                return;
              }
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: FractionallySizedBox(
              heightFactor: 0.6, // 화면 높이의 50% 차지
              child: UserGuideScreen(
                onFinish: () {
                  Navigator.of(context).pop(); // 모달 닫기
                },
              ),
            ));
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 루트 폴더 화면인 경우에만 타임스탬프 감지
    if (widget.folderId == null) {
      final foldersProvider =
          Provider.of<FoldersProvider>(context, listen: false);

      if (foldersProvider.rootFolderRefreshTimestamp !=
              _lastRootFolderRefreshTimestamp &&
          foldersProvider.rootFolderRefreshTimestamp > 0 &&
          !_isRefreshing) {
        _lastRootFolderRefreshTimestamp =
            foldersProvider.rootFolderRefreshTimestamp;
        log('🔄 Root folder refresh detected in didChangeDependencies! (timestamp: $_lastRootFolderRefreshTimestamp)');

        _isRefreshing = true;

        // 비동기 작업 실행
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            log('🔄 Starting _loadFolderData...');
            await _loadFolderData();
            if (mounted) {
              setState(() {
                _isRefreshing = false;
              });
            }
            log('✅ Root folder refresh completed!');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(themeProvider, foldersProvider), // 상단 AppBar 추가
          body: !(authService.isLoggedIn == LoginStatus.login)
              ? _buildLoginPrompt(themeProvider)
              : RefreshIndicator(
                  onRefresh: () async {
                    await fetchFoldersAndProblems();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildFolderAndProblemGrid(themeProvider),
                      ],
                    ),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton:
              (authService.isLoggedIn == LoginStatus.login && !_isSelectionMode)
                  ? _buildQuickCreateFab(themeProvider)
                  : null,
        ));
  }

  AppBar _buildAppBar(
      ThemeHandler themeProvider, FoldersProvider foldersProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      backgroundColor: Colors.white,
      title: StandardText(
        text: _isSelectionMode
            ? '삭제할 항목 선택'
            : ((_currentFolder?.parentFolder?.folderId != null &&
                    _currentFolder?.folderName != null)
                ? _currentFolder!.folderName
                : '책장'),
        fontSize: 18,
        color: themeProvider.primaryColor,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isSelectionMode ? Icons.close : Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: () {
                  if (_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = false;
                      _isQuickCreateOpen = false;
                      _selectedFolderIds.clear();
                      _selectedProblemIds.clear();
                    });
                  } else {
                    _showActionDialog(foldersProvider, themeProvider);
                  }
                }, // 더보기 버튼을 눌렀을 때 다이얼로그
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCreateFab(ThemeHandler themeProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isQuickCreateOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildQuickCreateAction(
                        label: '공책 추가',
                        icon: Icons.create_new_folder_outlined,
                        themeProvider: themeProvider,
                        onTap: () async {
                          setState(() => _isQuickCreateOpen = false);
                          FirebaseAnalytics.instance
                              .logEvent(name: 'folder_create_button_click');
                          await _showCreateFolderDialog();
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildQuickCreateAction(
                        label: '오답노트 작성',
                        icon: Icons.note_add_outlined,
                        themeProvider: themeProvider,
                        onTap: () async {
                          setState(() => _isQuickCreateOpen = false);
                          await _navigateToProblemRegisterInCurrentFolder();
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.centerRight,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: _isQuickCreateOpen
              ? FloatingActionButton(
                  key: const ValueKey('quick_fab_open'),
                  heroTag: 'directory_quick_create_fab_open',
                  onPressed: () {
                    setState(() {
                      _isQuickCreateOpen = false;
                    });
                  },
                  elevation: 2,
                  backgroundColor: Colors.grey[700],
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                )
              : FloatingActionButton.extended(
                  key: const ValueKey('quick_fab_closed'),
                  heroTag: 'directory_quick_create_fab_closed',
                  onPressed: () {
                    setState(() {
                      _isQuickCreateOpen = true;
                    });
                  },
                  elevation: 2,
                  backgroundColor: themeProvider.primaryColor,
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const StandardText(
                    text: '추가',
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuickCreateAction({
    required String label,
    required IconData icon,
    required ThemeHandler themeProvider,
    required Future<void> Function() onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: themeProvider.primaryColor,
              ),
              const SizedBox(width: 8),
              StandardText(
                text: label,
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공책 생성 다이얼로그 출력
  Future<void> _showCreateFolderDialog() async {
    await _showFolderNameDialog(
      dialogTitle: '공책 추가',
      defaultFolderName: '', // 폴더 생성 시에는 기본값이 없음
      onFolderNameSubmitted: (folderName) async {
        final foldersProvider =
            Provider.of<FoldersProvider>(context, listen: false);
        await foldersProvider.createFolder(folderName,
            parentFolderId: _currentFolder?.folderId);

        // 현재 화면 새로고침
        await _loadFolderData();
      },
    );
  }

  Future<void> _navigateToProblemRegisterInCurrentFolder() async {
    FirebaseAnalytics.instance
        .logEvent(name: 'directory_create_problem_note_click');

    if (_currentFolder == null) return;

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 작성 화면의 기본 공책을 현재 공책으로 고정
    await foldersProvider.moveToFolder(_currentFolder!.folderId);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemRegisterScreen(
          problemModel: null,
          isEditMode: false,
          initialFolderId: _currentFolder?.folderId,
        ),
      ),
    );

    // 작성 완료 후 현재 공책 화면으로 복귀 시 즉시 반영
    if (!mounted || result != true || _currentFolder == null) return;

    await foldersProvider.refreshFolder(_currentFolder!.folderId);
    await _loadFolderData();
  }

  void _showActionDialog(
      FoldersProvider foldersProvider, ThemeHandler themeProvider) {
    FirebaseAnalytics.instance
        .logEvent(name: 'directory_Screen_action_dialog_click');

    final openTime = DateTime.now();
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      builder: (context) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) <
                const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 핸들바
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 타이틀
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note,
                            color: themeProvider.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StandardText(
                          text: '공책 편집하기',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 메뉴 아이템들
                    _buildActionItem(
                      icon: Icons.add_circle_outline,
                      iconColor: themeProvider.primaryColor,
                      title: '공책 추가하기',
                      onTap: () {
                        Navigator.pop(context);
                        FirebaseAnalytics.instance.logEvent(
                            name: 'directory_create_folder_button_click');
                        _showCreateFolderDialog();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.note_add_outlined,
                      iconColor: themeProvider.primaryColor,
                      title: '오답노트 작성하기',
                      onTap: () async {
                        Navigator.pop(context);
                        await _navigateToProblemRegisterInCurrentFolder();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.drive_file_rename_outline,
                      iconColor: themeProvider.primaryColor,
                      title: '공책 이름 수정하기',
                      onTap: () {
                        Navigator.pop(context);
                        FirebaseAnalytics.instance
                            .logEvent(name: 'directory_rename_button_click');
                        _showRenameFolderDialog(foldersProvider);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.drive_file_move_outline,
                      iconColor: themeProvider.primaryColor,
                      title: '공책 위치 변경하기',
                      onTap: () {
                        Navigator.pop(context);
                        FirebaseAnalytics.instance.logEvent(
                            name: 'directory_path_change_button_click');
                        _showMoveFolderDialog(foldersProvider);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(
                      icon: Icons.delete_outline,
                      iconColor: Colors.red,
                      title: '공책 편집하기',
                      titleColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _isSelectionMode = true;
                        });
                        FirebaseAnalytics.instance
                            .logEvent(name: 'directory_enable_edit_mode');
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardText(
                text: title,
                fontSize: 16,
                color: titleColor ?? Colors.black87,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameFolderDialog(FoldersProvider foldersProvider) async {
    await _showFolderNameDialog(
      dialogTitle: '공책 이름 변경',
      defaultFolderName: _currentFolder?.folderName ?? '',
      onFolderNameSubmitted: (newName) async {
        await _renameFolder(newName);
      },
    );
  }

  Future<void> _renameFolder(
    String newName,
  ) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.updateFolder(newName, _currentFolder!.folderId, null);

    // 데이터 다시 로드
    await _loadFolderData();
  }

  // 폴더 이동 다이얼로그 출력
  Future<void> _showMoveFolderDialog(FoldersProvider foldersProvider) async {
    // 루트 폴더인지 확인
    if (_currentFolder?.parentFolder?.folderId == null) {
      _showCannotMoveRootFolderDialog();
      return;
    }

    final int? selectedFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => const FolderPickerDialog(),
    );

    if (selectedFolderId != null) {
      final oldParentFolderId = _currentFolder?.parentFolder?.folderId;
      final currentFolderId = _currentFolder!.folderId;

      // 부모 폴더 변경
      await foldersProvider.updateFolder(
        _currentFolder!.folderName,
        currentFolderId,
        selectedFolderId,
      );

      // 기존 부모/새 부모/현재 폴더 캐시를 모두 무효화해 즉시 반영
      if (oldParentFolderId != null) {
        await foldersProvider.refreshFolder(oldParentFolderId);
      }
      await foldersProvider.refreshFolder(selectedFolderId);
      await foldersProvider.refreshFolder(currentFolderId);

      if (!mounted) return;

      // 현재 화면 데이터 다시 로드
      await _loadFolderData();

      SnackBarDialog.showSnackBar(
        context: context,
        message: '공책 위치가 변경되었습니다.',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  // 루트 폴더 위치 변경 시 경고 다이얼로그 출력
  Future<void> _showCannotMoveRootFolderDialog() async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return _buildPhoneWidthDialog(
          Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const StandardText(
                        text: '공책 위치 변경 불가',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 내용
                  const StandardText(
                    text: '책장의 위치를 변경할 수 없습니다.',
                    fontSize: 15,
                    color: Colors.black87,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // 버튼
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const StandardText(
                        text: '확인',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(ThemeHandler themeProvider) {
    return Center(
      child: StandardText(
        text: '로그인을 통해 작성한 오답노트를 확인해보세요!',
        fontSize: 16,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Future<void> _showFolderNameDialog({
    required String dialogTitle,
    required String defaultFolderName,
    required Function(String) onFolderNameSubmitted,
  }) async {
    TextEditingController folderNameController =
        TextEditingController(text: defaultFolderName);
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    final standardTextStyle = const StandardText(text: '').getTextStyle();
    final openTime = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) <
                const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(dialogContext)) {
              Navigator.pop(dialogContext);
            }
          },
          child: _buildPhoneWidthDialog(
            Dialog(
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
                    // 헤더
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: themeProvider.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StandardText(
                          text: dialogTitle,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 입력 필드
                    TextField(
                      controller: folderNameController,
                      autofocus: true,
                      style: standardTextStyle.copyWith(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '공책 이름을 입력하세요',
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
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 액션 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const StandardText(
                            text: '취소',
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            if (folderNameController.text.isNotEmpty) {
                              onFolderNameSubmitted(folderNameController.text);
                              Navigator.pop(dialogContext);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor: themeProvider.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const StandardText(
                            text: '확인',
                            fontSize: 14,
                            color: Colors.white,
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
      },
    );
  }

  Widget _buildFolderAndProblemGrid(ThemeHandler themeProvider) {
    return Expanded(
        child: Column(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              // 로컬 상태 사용 (Provider와 독립적)
              var currentSubfolders = _localSubfolders;
              var currentProblems = _localProblems;
              final isLoadingMore = _isLoadingSubfolders || _isLoadingProblems;

              // 초기 로딩 중이면 로딩 인디케이터 표시
              if (_isInitialLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // 로딩 완료 후에도 데이터가 없으면 빈 화면 표시
              if (currentSubfolders.isEmpty && currentProblems.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/Icon/GreenNote.svg', // 아이콘 경로
                            width: 100, // 적절한 크기 설정
                            height: 100,
                          ),
                          const SizedBox(height: 40), // 아이콘과 텍스트 사이 간격
                          const StandardText(
                            text: '작성한 오답노트를\n공책에 저장해 관리하세요!',
                            fontSize: 16,
                            color: Colors.black,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              FirebaseAnalytics.instance.logEvent(
                                  name: 'directory_empty_create_problem_click');
                              await _navigateToProblemRegisterInCurrentFolder();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  themeProvider.primaryColor, // primaryColor 적용
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const StandardText(
                              text: '오답노트 작성하기',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final totalItems =
                  currentSubfolders.length + currentProblems.length;
              final hasMore = _subfolderHasNext || _problemHasNext;

              return ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: totalItems + (isLoadingMore || hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // 로딩 인디케이터 표시
                  if (index == totalItems) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (index < currentSubfolders.length) {
                    var subfolder = currentSubfolders[index];
                    return _buildFolderTile(subfolder, themeProvider, index);
                  } else {
                    var problem =
                        currentProblems[index - currentSubfolders.length];
                    return _buildProblemTile(problem, themeProvider);
                  }
                },
              );
            },
          ),
        ),
        if (_isSelectionMode) _buildBottomActionButtons(themeProvider),
      ],
    ));
  }

  Widget _buildFolderTile(
      FolderThumbnailModel folder, ThemeHandler themeProvider, int index) {
    final isSelected = _selectedFolderIds.contains(folder.folderId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          // 폴더를 클릭했을 때 해당 폴더로 이동
          FirebaseAnalytics.instance
              .logEvent(name: 'move_to_folder', parameters: {
            'folder_id': folder.folderId,
          });

          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedFolderIds.remove(folder.folderId);
              } else {
                _selectedFolderIds.add(folder.folderId);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return DirectoryScreen(folderId: folder.folderId);
              }),
            ).then((_) {
              // 하위 폴더에서 돌아왔을 때 현재 폴더 데이터 새로고침
              _loadFolderData();
            });
          }
        },
        child: LongPressDraggable<FolderThumbnailModel>(
          data: folder,
          feedback: Material(
            child: SizedBox(
              width: 50,
              height: 70,
              child: SvgPicture.asset(
                NoteIconHandler.getNoteIcon(index), // 헬퍼 클래스로 아이콘 설정
                width: 50,
                height: 50,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _folderTileContent(folder, themeProvider, index),
          ),
          onDragStarted: () {
            HapticFeedback.lightImpact();
          },
          child: DragTarget<ProblemModel>(
            onAcceptWithDetails: (details) async {
              // 문제를 드롭하면 폴더로 이동
              ProblemRegisterModel problemRegisterModel = ProblemRegisterModel(
                problemId: details.data.problemId,
                folderId: folder.folderId,
              );
              await _moveProblemToFolder(problemRegisterModel);
            },
            builder: (context, candidateData, rejectedData) {
              return DragTarget<FolderThumbnailModel>(
                onAcceptWithDetails: (details) async {
                  // 폴더를 드롭하면 자식 폴더로 이동
                  await _moveFolderToNewParent(details.data, folder.folderId);
                },
                builder: (context, candidateData, rejectedData) {
                  return _folderTileContent(folder, themeProvider, index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _folderTileContent(
      FolderThumbnailModel folder, ThemeHandler themeProvider, int index) {
    final isSelected = _selectedFolderIds.contains(folder.folderId);
    return Container(
      padding: const EdgeInsets.all(12.0),
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
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.red)
                : SvgPicture.asset(
                    NoteIconHandler.getNoteIcon(index),
                    width: 30,
                    height: 30,
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StandardText(
                  text: folder.folderName.isNotEmpty
                      ? folder.folderName
                      : '제목 없음',
                  color: Colors.black,
                  fontSize: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    final isSelected = _selectedProblemIds.contains(problem.problemId);

    final imageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // 아이템 간 간격 추가
      child: GestureDetector(
        onTap: () {
          FirebaseAnalytics.instance
              .logEvent(name: 'move_to_problem', parameters: {
            'problem_id': problem.problemId,
          });

          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProblemIds.remove(problem.problemId);
              } else {
                _selectedProblemIds.add(problem.problemId);
              }
            });
          } else {
            navigateToProblemDetail(context, problem.problemId);
          }
        },
        child: LongPressDraggable<ProblemModel>(
          data: problem,
          feedback: Material(
            child: SizedBox(
              width: 50,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: DisplayImage(
                  imagePath: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _problemTileContent(problem, themeProvider),
          ),
          onDragStarted: () {
            HapticFeedback.lightImpact();
          },
          child: DragTarget<FolderThumbnailModel>(
            onAcceptWithDetails: (details) async {
              // 문제를 드롭하면 해당 폴더로 이동
              ProblemRegisterModel problemRegisterModel = ProblemRegisterModel(
                  problemId: problem.problemId,
                  folderId: details.data.folderId);
              await _moveProblemToFolder(problemRegisterModel);
            },
            builder: (context, candidateData, rejectedData) {
              return _problemTileContent(problem, themeProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _problemTileContent(ProblemModel problem, ThemeHandler themeProvider) {
    final isSelected = _selectedProblemIds.contains(problem.problemId);
    final imageUrl = problem.problemImageDataList != null &&
            problem.problemImageDataList!.isNotEmpty
        ? problem.problemImageDataList!.first.imageUrl
        : null;

    return Container(
      padding: const EdgeInsets.all(12.0),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: isSelected
                  ? Icon(Icons.check, color: themeProvider.primaryColor)
                  : DisplayImage(
                      imagePath: imageUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    /*
                    _getTemplateIcon(problem.templateType!),
                    const SizedBox(width: 8),

                     */
                    Flexible(
                      child: StandardText(
                        text: (problem.reference != null &&
                                problem.reference!.isNotEmpty)
                            ? problem.reference!
                            : '제목 없음',
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                StandardText(
                  text: problem.createdAt != null
                      ? '작성 일시: ${formatDateTime(problem.createdAt!)}'
                      : '작성 일시: 정보 없음',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8)),
              onPressed: () {
                // 선택 모드 취소
                setState(() {
                  _isSelectionMode = false;
                  _selectedFolderIds.clear();
                  _selectedProblemIds.clear();
                });
              },
              child: const StandardText(
                text: '취소하기',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8)),
              onPressed: () {
                if (_selectedFolderIds.isNotEmpty ||
                    _selectedProblemIds.isNotEmpty) {
                  _confirmDelete();
                }
              },
              child: const StandardText(
                text: '삭제하기',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedItems() async {
    if (_currentFolder == null) return;

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    // 로딩 다이얼로그 표시
    LoadingDialog.show(context, '폴더 정리 중...');

    try {
      // 선택된 폴더 삭제
      if (_selectedFolderIds.isNotEmpty) {
        await foldersProvider.deleteFolders(_selectedFolderIds);
      }

      // 선택된 문제 삭제
      if (_selectedProblemIds.isNotEmpty) {
        await problemsProvider.deleteProblems(_selectedProblemIds);
      }

      // 캐시 삭제 후 새로고침 (삭제된 항목이 화면에서 사라지도록)
      await foldersProvider.refreshFolder(_currentFolder!.folderId);

      // 로딩 다이얼로그 닫기
      if (mounted) {
        LoadingDialog.hide(context);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedFolderIds.clear();
        _selectedProblemIds.clear();
      });

      // 삭제 성공 메시지
      if (mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '선택된 항목이 삭제되었습니다!',
          backgroundColor: Theme.of(context).primaryColor,
        );
      }

      // 데이터 다시 로드
      await _loadFolderData();
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        LoadingDialog.hide(context);
      }

      // 에러 처리
      log('Error deleting items: $e');
      if (mounted) {
        SnackBarDialog.showSnackBar(
          context: context,
          message: '항목 삭제 중 오류가 발생했습니다.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _confirmDelete() {
    final theme = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => _buildPhoneWidthDialog(
        Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '삭제 확인',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '선택한 항목을 정말 삭제하시겠습니까?',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '취소',
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteSelectedItems();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const StandardText(
                          text: '삭제',
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
  }

  Widget _buildPhoneWidthDialog(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: child,
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  Future<void> _moveFolderToNewParent(
      FolderThumbnailModel folder, int? newParentFolderId) async {
    if (newParentFolderId == null) {
      log('New parent folder ID is null.');
      return;
    }

    FirebaseAnalytics.instance.logEvent(name: 'folder_move', parameters: {
      'folder_id': folder.folderId,
      'target_folder_id': newParentFolderId,
    });

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 폴더 업데이트 (서버 + 메타데이터 갱신)
    await foldersProvider.updateFolder(
        folder.folderName, folder.folderId, newParentFolderId);

    // 출발지 폴더 캐시 갱신 (이동한 폴더가 목록에서 사라지도록)
    if (_currentFolder != null) {
      await foldersProvider.refreshFolder(_currentFolder!.folderId);
    }

    // 목적지 폴더 캐시 갱신 (옮긴 폴더가 목적지에 나타나도록)
    await foldersProvider.refreshFolder(newParentFolderId);

    // 로컬 데이터 새로고침
    await _loadFolderData();

    if (mounted) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '공책이 성공적으로 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  Future<void> _moveProblemToFolder(
      ProblemRegisterModel problemRegisterModel) async {
    if (problemRegisterModel.folderId == null) {
      log('Problem ID or folderId is null. Cannot move the problem.');
      return; // 문제 ID 또는 폴더 ID가 null이면 실행하지 않음
    }

    FirebaseAnalytics.instance.logEvent(name: 'problem_path_edit', parameters: {
      'problem_id': problemRegisterModel.problemId!,
      'target_folder_id': problemRegisterModel.folderId!,
    });

    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 문제 업데이트 (서버 + ProblemsProvider 캐시 갱신)
    await problemsProvider.updateProblem(problemRegisterModel);

    // 출발지 폴더 캐시 갱신 (이동한 문제가 목록에서 사라지도록)
    if (_currentFolder != null) {
      await foldersProvider.refreshFolder(_currentFolder!.folderId);
    }

    // 목적지 폴더 캐시 갱신 (옮긴 문제가 목적지에 나타나도록)
    await foldersProvider.refreshFolder(problemRegisterModel.folderId!);

    // 로컬 데이터 새로고침
    await _loadFolderData();

    if (mounted) {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '오답노트가 이동되었습니다!',
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  List<ProblemThumbnailModel> loadProblems() {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    if (foldersProvider.currentProblems.isNotEmpty) {
      return foldersProvider.currentProblems
          .map((problem) => ProblemThumbnailModel.fromProblem(problem))
          .toList();
    } else {
      log('No problems loaded');
      return [];
    }
  }

  Future<void> fetchFoldersAndProblems() async {
    // Pull-to-refresh: 캐시 무시하고 강제 새로고침
    if (_currentFolder == null) return;

    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 현재 폴더의 캐시 삭제
    await foldersProvider.refreshFolder(_currentFolder!.folderId);

    // 로컬 데이터 다시 로드
    await _loadFolderData();
  }

  void navigateToProblemDetail(BuildContext context, int problemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProblemDetailScreen(problemId: problemId),
      ),
    ).then((value) async {
      // 문제 삭제 또는 수정 시 화면 새로고침
      if (value == true && _currentFolder != null) {
        final foldersProvider =
            Provider.of<FoldersProvider>(context, listen: false);

        // 캐시 삭제 후 새로고침
        await foldersProvider.refreshFolder(_currentFolder!.folderId);
        await _loadFolderData();
      }
    });
  }
}
