import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ono/GlobalModule/Theme/LoadingDialog.dart';
import 'package:ono/GlobalModule/Theme/SnackBarDialog.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../ProblemDetail/ProblemDetailScreenV2.dart';
import '../../Model/ProblemPracticeModel.dart';
import '../../Provider/ProblemPracticeProvider.dart';
import 'PracticeProblemSelectionScreen.dart';

class PracticeThumbnailScreen extends StatefulWidget {
  const PracticeThumbnailScreen({super.key});

  @override
  _ProblemPracticeScreen createState() => _ProblemPracticeScreen();
}

class _ProblemPracticeScreen extends State<PracticeThumbnailScreen> {
  bool _isSelectionMode = false;
  final List<int> _selectedPracticeIds = [];

  @override
  void initState() {
    super.initState();
    _fetchPracticeThumbnails();
  }

  Future<void> _fetchPracticeThumbnails() async {
    final provider =
        Provider.of<ProblemPracticeProvider>(context, listen: false);
    await provider.fetchAllPracticeThumbnails();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      backgroundColor: Colors.white,
      body: Consumer<ProblemPracticeProvider>(
        builder: (context, provider, child) {
          if (provider.practiceThumbnails == null) {
            return _buildLoadingIndicator();
          } else if (provider.practiceThumbnails!.isEmpty) {
            return _buildEmptyState(themeProvider);
          } else {
            return _buildPracticeListView(
                provider.practiceThumbnails!, themeProvider);
          }
        },
      ),
      bottomNavigationBar: _isSelectionMode ? _buildBottomActionButtons(themeProvider) : null,
      floatingActionButton: _buildFloatingActionButton(context, themeProvider),
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
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
                onPressed: _showBottomSheetForDeletion,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBottomSheetForDeletion() {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // 패딩 추가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // 타이틀 아래 여백 추가
                  child: StandardText(
                    text: '복습 리스트 편집하기', // 타이틀 텍스트
                    fontSize: 20,
                    color: themeProvider.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0), // 텍스트 간격 조정
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const StandardText(
                      text: '복습 리스트 삭제하기',
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
        );
      },
    );
  }

  Widget _buildBottomActionButtons(ThemeHandler themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                    fontSize: 16,
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
                      text:  '${_selectedPracticeIds.length}',
                      fontSize: 14,
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
            text: '복습 리스트 삭제',
            fontSize: 18,
            color: Colors.black,
          ),
          content: const StandardText(
            text: '정말로 이 복습 리스트를 삭제하시겠습니까?',
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
                bool isDelete = await provider.deletePractices(deletePracticeIds);

                if(isDelete){
                  SnackBarDialog.showSnackBar(
                      context: context,
                      message: '공책이 삭제되었습니다!',
                      backgroundColor: themeProvider.primaryColor);
                } else{
                  SnackBarDialog.showSnackBar(
                      context: context,
                      message: '삭제 과정에서 문제가 발생했습니다!',
                      backgroundColor: Colors.red);
                }

                setState(() {
                  _isSelectionMode = false;
                  _selectedPracticeIds.clear();
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/Icon/RainbowNote.svg',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 40),
          StandardText(
            text: '오답 복습 루틴을 추가해보세요!',
            fontSize: 16,
            color: themeProvider.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeListView(List<ProblemPracticeModel> practiceThumbnails,
      ThemeHandler themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: practiceThumbnails.length,
      itemBuilder: (context, index) {
        final practice = practiceThumbnails[index];
        return _buildPracticeItem(practice, themeProvider);
      },
    );
  }

  Widget _buildPracticeItem(
      ProblemPracticeModel practice, ThemeHandler themeProvider) {
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
          _navigateToProblemDetail(practice);
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

  Future<void> _navigateToProblemDetail(ProblemPracticeModel practice) async {
    final provider = Provider.of<ProblemPracticeProvider>(context, listen: false);
    LoadingDialog.show(context, '복습 루틴 생성 중...');

    await provider.fetchPracticeProblems(practice.practiceId);

    LoadingDialog.hide(context);

    if (provider.problems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProblemDetailScreenV2(
            problemId: provider.problemIds[0],
            isPractice: true,
          ),
        ),
      );
    } else {
      SnackBarDialog.showSnackBar(
        context: context,
        message: '복습 루틴이 비어있습니다!',
        backgroundColor: Colors.red,
      );
    }
  }


  BoxDecoration _buildBoxDecoration(bool isSelected, ThemeHandler themeProvider) {
    return BoxDecoration(
      color: isSelected ? themeProvider.primaryColor.withOpacity(0.1) : Colors.white,
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
        color: isSelected ? themeProvider.primaryColor : Colors.grey[200],
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
      ProblemPracticeModel practice, ThemeHandler themeProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StandardText(
            text: practice.practiceTitle,
            fontSize: 18,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag('${practice.practiceSize} 문제', themeProvider),
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
            : themeProvider.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: StandardText(
        text: text,
        fontSize: 12,
        color: Colors.white,
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

  Widget _buildFloatingActionButton(
      BuildContext context, ThemeHandler themeProvider) {
    return Stack(
      children: [
        Positioned(
          bottom: 20,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: themeProvider.primaryColor, width: 2),
            ),
            child: FloatingActionButton(
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
          ),
        ),
      ],
    );
  }

  String? formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }
}
