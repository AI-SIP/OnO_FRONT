import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Module/Dialog/SnackBarDialog.dart';
import 'package:provider/provider.dart';

import '../../Model/PracticeNote/PracticeNoteDetailModel.dart';
import '../../Model/PracticeNote/PracticeNoteThumbnailModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/PracticeNoteProvider.dart';
import 'PracticeDetailScreen.dart';
import 'PracticeProblemSelectionScreen.dart';

class PracticeThumbnailScreen extends StatefulWidget {
  const PracticeThumbnailScreen({super.key});

  @override
  _ProblemPracticeScreen createState() => _ProblemPracticeScreen();
}

class _ProblemPracticeScreen extends State<PracticeThumbnailScreen> {
  bool _isSelectionMode = false;
  final List<int> _selectedPracticeIds = [];
  late ScrollController _scrollController;
  int _lastPracticeRefreshTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 80% 이상 내려가면 다음 페이지 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final provider =
          Provider.of<ProblemPracticeProvider>(context, listen: false);
      if (provider.hasNext && !provider.isLoading) {
        provider.loadMorePracticeThumbnails();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final practiceProvider = Provider.of<ProblemPracticeProvider>(context);

    // 복습 노트 생성/수정 후 타임스탬프가 변경되면 자동 새로고침
    if (practiceProvider.practiceRefreshTimestamp !=
            _lastPracticeRefreshTimestamp &&
        practiceProvider.practiceRefreshTimestamp > 0) {
      _lastPracticeRefreshTimestamp = practiceProvider.practiceRefreshTimestamp;

      // PostFrameCallback을 사용하여 안전하게 상태 업데이트
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshPracticeThumbnails();
      });
    }

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshPracticeThumbnails,
        child: Consumer<ProblemPracticeProvider>(
          builder: (context, provider, child) {
            if (provider.practiceThumbnails.isEmpty && !provider.isLoading) {
              return _buildEmptyState(themeProvider);
            } else {
              return _buildPracticeListView(provider, themeProvider);
            }
          },
        ),
      ),
      bottomNavigationBar: _isSelectionMode
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 추가
              child: _buildBottomActionButtons(themeProvider),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.white,
      title: StandardText(
        text: _isSelectionMode ? '삭제할 항목 선택' : '오답 복습',
        fontSize: 20,
        color: themeProvider.primaryColor,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              FloatingActionButton(
                heroTag: 'create_problem_practice',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PracticeProblemSelectionScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: SvgPicture.asset("assets/Icon/addPractice.svg"),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: _showBottomSheet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBottomSheet() {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    final openTime = DateTime.now();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isDismissible: false,
      builder: (context) {
        return TapRegion(
          onTapOutside: (_) {
            // Workaround for iPadOS 26.1 bug: https://github.com/flutter/flutter/issues/177992
            if (DateTime.now().difference(openTime) < const Duration(milliseconds: 500)) {
              return;
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 20.0, horizontal: 10.0), // 패딩 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 타이틀 아래 여백 추가
                  child: StandardText(
                    text: '복습 노트 편집하기', // 타이틀 텍스트
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.add, color: Colors.black),
                    title: const StandardText(
                      text: '복습 노트 생성하기',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onTap: () {
                      Navigator.pop(context); // BottomSheet 닫기
                      // PracticeProblemSelectionScreen으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PracticeProblemSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '복습 노트 삭제하기',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    onTap: () {
                      Navigator.pop(context); // BottomSheet 닫기
                      setState(() {
                        _isSelectionMode = true;
                        _selectedPracticeIds.clear();
                      });
                    },
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedPracticeIds.clear();
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
                backgroundColor: themeProvider.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _selectedPracticeIds.isNotEmpty
                  ? () => _showDeletePracticeDialog(_selectedPracticeIds)
                  : () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const StandardText(
                    text: '삭제하기',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: StandardText(
                      text: '${_selectedPracticeIds.length}',
                      fontSize: 12,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletePracticeDialog(List<int> deletePracticeIds) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const StandardText(
            text: '복습 노트 삭제',
            fontSize: 18,
            color: Colors.black,
          ),
          content: const StandardText(
            text: '정말로 이 복습 노트를 삭제하시겠습니까?',
            fontSize: 16,
            color: Colors.black,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                final provider = Provider.of<ProblemPracticeProvider>(context,
                    listen: false);
                await provider.deletePractices(deletePracticeIds);

                setState(() {
                  _isSelectionMode = false;
                  _selectedPracticeIds.clear();
                });

                Future.delayed(Duration.zero, () {
                  SnackBarDialog.showSnackBar(
                    context: context,
                    message: '복습 노트가 삭제되었습니다!',
                    backgroundColor: themeProvider.primaryColor,
                  );
                });
              },
              child: const StandardText(
                text: '삭제',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(ThemeHandler themeProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              SvgPicture.asset(
                'assets/Icon/BigGreenFrog.svg',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 40),
              const StandardText(
                text: '작성한 오답노트로 복습 노트를\n 생성해 시험을 준비하세요!',
                fontSize: 16,
                color: Colors.black,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // 복습 노트 추가 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PracticeProblemSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor, // primaryColor 적용
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const StandardText(
                  text: '복습 노트 추가하기',
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

  Widget _buildPracticeListView(
      ProblemPracticeProvider provider, ThemeHandler themeProvider) {
    final thumbnails = provider.practiceThumbnails;
    final isLoadingMore = provider.isLoading;
    final hasMore = provider.hasNext;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: thumbnails.length + (isLoadingMore || hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 로딩 인디케이터
        if (index == thumbnails.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final practice = thumbnails[index];
        return _buildPracticeItem(practice, themeProvider);
      },
    );
  }

  Widget _buildPracticeItem(
      PracticeNoteThumbnails practice, ThemeHandler themeProvider) {
    final isSelected = _selectedPracticeIds.contains(practice.practiceId);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            isSelected
                ? _selectedPracticeIds.remove(practice.practiceId)
                : _selectedPracticeIds.add(practice.practiceId);
          });
        } else {
          _navigateToPracticeDetail(practice.practiceId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: _buildBoxDecoration(isSelected, themeProvider),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIconContainer(isSelected, themeProvider),
              const SizedBox(width: 16),
              _buildPracticeInfo(practice, themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPracticeDetail(int practiceId) async {
    final practiceProvider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    LoadingDialog.show(context, '복습 노트 로딩 중...');

    // 상세 정보 조회 및 이동
    await practiceProvider.fetchPracticeNote(practiceId);
    await practiceProvider.moveToPractice(practiceId);
    LoadingDialog.hide(context);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeDetailScreen(
            practice: practiceProvider.currentPracticeNote!),
      ),
    );

    // 복습을 완료한 경우(result == true)에만 해당 썸네일 업데이트
    if (result == true) {
      await practiceProvider.updateSinglePracticeThumbnail(practiceId);
    }
    // 그 외의 경우(조회만 한 경우)는 캐시 유지
  }

  BoxDecoration _buildBoxDecoration(
      bool isSelected, ThemeHandler themeProvider) {
    return BoxDecoration(
      color: isSelected
          ? themeProvider.primaryColor.withOpacity(0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildIconContainer(bool isSelected, ThemeHandler themeProvider) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withOpacity(0.1),
      ),
      child: Center(
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white)
            : SvgPicture.asset(
                'assets/Icon/RainbowNote.svg',
                width: 40,
                height: 40,
              ),
      ),
    );
  }

  Widget _buildPracticeInfo(
      PracticeNoteThumbnails practice, ThemeHandler themeProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: practice.practiceTitle.isNotEmpty
                ? practice.practiceTitle
                : "제목 없음",
            fontSize: 18,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              practice.practiceCount >= 3
                  ? _buildTag('복습 완료', themeProvider, highlight: true)
                  : _buildTag('${practice.practiceCount}회 복습', themeProvider),
              const SizedBox(width: 8),
              ..._buildStatusIcons(practice.practiceCount),
            ],
          ),
          const SizedBox(height: 8),
          StandardText(
            text:
                '마지막 복습 날짜: ${formatDateTime(practice.lastSolvedAt) ?? '복습 기록 없음'}',
            fontSize: 12,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, ThemeHandler themeProvider,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? themeProvider.primaryColor
            : themeProvider.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: StandardText(
        text: text,
        fontSize: 12,
        color: highlight ? Colors.white : themeProvider.primaryColor,
      ),
    );
  }

  List<Widget> _buildStatusIcons(int practiceCount) {
    List<String> icons = [
      'assets/Icon/SmallGreenFrog.svg',
      'assets/Icon/SmallYellowFrog.svg',
      'assets/Icon/SmallPinkFrog.svg'
    ];

    return List<Widget>.generate(3, (index) {
      return Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: SvgPicture.asset(
          icons[index],
          width: 20,
          height: 20,
          color: index < practiceCount ? null : Colors.white,
        ),
      );
    });
  }

  String? formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  Future<void> _fetchAllPracticeContents() async {
    final provider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    await provider.fetchAllPracticeContents();
  }

  Future<void> _refreshPracticeThumbnails() async {
    final provider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    await provider.refreshPracticeThumbnails();
  }
}
