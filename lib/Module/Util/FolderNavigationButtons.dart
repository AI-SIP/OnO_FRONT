import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Model/Common/ProblemImageDataType.dart';
import 'package:ono/Model/Problem/ProblemImageDataRegisterModel.dart';
import 'package:ono/Module/Dialog/LoadingDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';
import 'package:ono/Service/Api/FileUpload/FileUploadService.dart';
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_previous_problem',
            );
            navigateToProblem(context, previousProblemId, isNext: false);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '< 이전 문제', fontSize: 14, color: themeProvider.primaryColor),
        ),

        // 복습 완료 버튼
        TextButton(
          onPressed: () =>
              showSolveDialog(context, problemList[currentIndex].problemId),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: isSolved
              ? Icon(
                  Icons.check, // 복습 완료 시 체크 아이콘만 표시
                  color: themeProvider.primaryColor,
                  size: 20,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min, // 터치 아이콘과 텍스트를 한 줄로 표시
                  children: [
                    Icon(
                      Icons.touch_app, // 복습 완료 전 터치 아이콘
                      color: themeProvider.primaryColor,
                      size: 15,
                    ),
                    const SizedBox(width: 10), // 아이콘과 텍스트 간 간격
                    StandardText(
                      text: '문제 복습', // 복습 완료 텍스트
                      fontSize: 15,
                      color: themeProvider.primaryColor,
                    ),
                  ],
                ),
        ),
        TextButton(
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(
              name: 'navigate_next_problem',
            );
            navigateToProblem(context, nextProblemId, isNext: true);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: themeProvider.primaryColor,
              width: 2.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
          child: StandardText(
              text: '다음 문제 >', fontSize: 14, color: themeProvider.primaryColor),
        ),
      ],
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
            return AlertDialog(
              backgroundColor: Colors.white,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              contentPadding: const EdgeInsets.all(15),
              titlePadding: const EdgeInsets.only(left: 20, top: 20, right: 20),
              title: const StandardText(
                text: '복습을 완료했나요?',
                fontSize: 18,
                color: Colors.black,
              ),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(15),
                child: GestureDetector(
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
                    width: double.maxFinite,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 60,
                                color: themeProvider.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              StandardText(
                                text: '풀이 이미지를 등록하세요',
                                color: themeProvider.primaryColor,
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const StandardText(
                    text: '취소',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (selectedImage != null) {
                            setState(() {
                              isLoading = true;
                            });

                            LoadingDialog.show(context, '오답 복습 중...');

                            try {
                              FileUploadService fileUploadService =
                                  FileUploadService();
                              String imageUrl = await fileUploadService
                                  .uploadImageFile(selectedImage!);

                              final problemImageDataRegisterModel =
                                  ProblemImageDataRegisterModel(
                                problemId: problemId,
                                imageUrl: imageUrl,
                                problemImageType: ProblemImageType.SOLVE_IMAGE,
                              );

                              final problemsProvider =
                                  Provider.of<ProblemsProvider>(context,
                                      listen: false);
                              await problemsProvider.registerProblemImageData(
                                  problemImageDataRegisterModel);

                              FirebaseAnalytics.instance.logEvent(
                                name: 'problem_solve',
                              );

                              setState(() {
                                isSolved = true;
                                isLoading = false;
                              });

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
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: themeProvider.primaryColor,
                          ),
                        )
                      : StandardText(
                          text: '문제 복습',
                          fontSize: 14,
                          color: themeProvider.primaryColor,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
