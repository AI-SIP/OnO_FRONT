import 'dart:developer';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Provider/UserProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:provider/provider.dart';

import '../../Exception/ApiException.dart';
import '../Dialog/SnackBarDialog.dart';
import '../Image/ImagePickerHandler.dart';
import '../Text/StandardText.dart';
import '../Theme/ThemeHandler.dart';

class FolderNavigationButtons extends StatefulWidget {
  final BuildContext context;
  final FoldersProvider foldersProvider;
  final int currentId;
  final VoidCallback onRefresh;

  const FolderNavigationButtons({
    super.key,
    required this.context,
    required this.foldersProvider,
    required this.currentId,
    required this.onRefresh,
  });

  @override
  _FolderNavigationButtonsState createState() =>
      _FolderNavigationButtonsState();
}

class _FolderNavigationButtonsState extends State<FolderNavigationButtons> {
  bool isSolved = false;
  final ImagePickerHandler _imagePickerHandler = ImagePickerHandler();
  XFile? selectedImage;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final problemList = widget.foldersProvider.currentProblems;
    double screenHeight = MediaQuery.of(context).size.height;

    if (problemList.isEmpty) {
      return const Center();
    }

    int currentIndex = -1;
    for (int index = 0; index < problemList.length; index++) {
      if (problemList[index].problemId == widget.currentId) {
        currentIndex = index;
        break;
      }
    }

    int previousProblemId = currentIndex > 0
        ? problemList[currentIndex - 1].problemId
        : problemList.last.problemId;
    int nextProblemId = currentIndex < problemList.length - 1
        ? problemList[currentIndex + 1].problemId
        : problemList.first.problemId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () =>
            showSolveDialog(context, problemList[currentIndex].problemId),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.01,
            vertical: screenHeight * 0.015,
          ),
          backgroundColor: themeProvider.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSolved
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  StandardText(
                    text: '복습 완료',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  StandardText(
                    text: '복습 인증',
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  void navigateToProblem(BuildContext context, int newProblemId,
      {required bool isNext}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProblemDetailScreen(problemId: newProblemId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 다음 문제인지 이전 문제인지에 따라 시작 위치와 애니메이션 설정
          final Offset begin =
              !isNext ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // 회전 애니메이션 설정
          return SlideTransition(
            position: offsetAnimation,
            child: RotationTransition(
              alignment: Alignment.bottomRight, // 오른쪽 아래를 기준으로 회전
              turns: Tween(begin: !isNext ? -0.1 : 0.1, end: 0.0)
                  .animate(animation), // 시계 방향으로 회전
              child: child,
            ),
          );
        },
      ),
    );
  }

  void showSolveDialog(BuildContext context, int problemId) {
    FirebaseAnalytics.instance.logEvent(name: 'problem_solve_button_click');

    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    bool isLoading = false; // 로딩 상태 변수 외부로 이동

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
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
                            Icons.touch_app,
                            color: themeProvider.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const StandardText(
                          text: '복습을 완료했나요?',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 이미지 선택 영역
                    GestureDetector(
                      onTap: () {
                        FirebaseAnalytics.instance.logEvent(
                          name: 'add_solve_image_button_click',
                        );

                        _imagePickerHandler.showImagePicker(context,
                            (pickedFile) async {
                          if (pickedFile != null) {
                            setState(() {
                              selectedImage = pickedFile;
                            });
                          }
                        });
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: themeProvider.primaryColor
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  StandardText(
                                    text: '풀이 이미지를 등록하세요',
                                    fontSize: 16,
                                    color: Colors.grey[600]!,
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(selectedImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 액션 버튼
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const StandardText(
                              text: '취소',
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (selectedImage != null) {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      LoadingDialog.show(context, '오답 복습 중...');

                                      try {
                                        // 파일을 직접 서버로 전송
                                        final problemsProvider =
                                            Provider.of<ProblemsProvider>(context,
                                                listen: false);

                                        await problemsProvider.problemService
                                            .registerProblemImageData(
                                          problemId: problemId,
                                          problemImages: [File(selectedImage!.path)],
                                          problemImageTypes: ['SOLVE_IMAGE'],
                                        );

                                        // 문제 정보 갱신
                                        await problemsProvider.fetchProblem(problemId);

                                        FirebaseAnalytics.instance.logEvent(
                                          name: 'problem_solve',
                                        );

                                        // 오답노트 복습 시 유저 정보 갱신 (경험치 업데이트)
                                        await Provider.of<UserProvider>(context,
                                                listen: false)
                                            .fetchUserInfo();

                                        setState(() {
                                          isSolved = true;
                                          isLoading = false;
                                        });

                                        log("problemId: ${problemId} solve");
                                        LoadingDialog.hide(context);
                                        Navigator.of(context).pop();

                                        SnackBarDialog.showSnackBar(
                                          context: context,
                                          message: '복습이 완료되었습니다!',
                                          backgroundColor: themeProvider.primaryColor,
                                        );

                                        widget.onRefresh();
                                      } on BadRequestException catch (e) {
                                        // 서버 에러 (예: 이미 오늘 복습 완료)
                                        setState(() {
                                          isLoading = false;
                                        });

                                        LoadingDialog.hide(context);
                                        Navigator.of(context).pop();

                                        SnackBarDialog.showSnackBar(
                                          context: context,
                                          message: e.getUserMessage(),
                                          backgroundColor: Colors.red,
                                        );
                                      } on NetworkException catch (e) {
                                        // 네트워크 에러
                                        setState(() {
                                          isLoading = false;
                                        });

                                        LoadingDialog.hide(context);

                                        SnackBarDialog.showSnackBar(
                                          context: context,
                                          message: e.getUserMessage(),
                                          backgroundColor: Colors.orange,
                                        );
                                      } on TimeoutException catch (e) {
                                        // 타임아웃 에러
                                        setState(() {
                                          isLoading = false;
                                        });

                                        LoadingDialog.hide(context);

                                        SnackBarDialog.showSnackBar(
                                          context: context,
                                          message: e.getUserMessage(),
                                          backgroundColor: Colors.orange,
                                        );
                                      } catch (e) {
                                        // 기타 에러
                                        setState(() {
                                          isLoading = false;
                                        });

                                        LoadingDialog.hide(context);

                                        SnackBarDialog.showSnackBar(
                                          context: context,
                                          message: '알 수 없는 오류가 발생했습니다.',
                                          backgroundColor: Colors.red,
                                        );
                                      }
                                    }
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isLoading
                                  ? Colors.grey[300]
                                  : themeProvider.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const StandardText(
                                    text: '복습 완료',
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
      },
    );
  }
}
