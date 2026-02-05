import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Model/Problem/ProblemRegisterModel.dart';
import '../../Module/Dialog/LoadingDialog.dart';
import '../../Module/Dialog/SnackBarDialog.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Module/Util/FolderPickerWidget.dart';
import '../../Provider/FoldersProvider.dart';
import '../../Provider/ProblemsProvider.dart';
import '../../Provider/ScreenIndexProvider.dart';
import '../../Provider/UserProvider.dart';
import '../../Service/Api/Problem/ProblemService.dart';
import 'Widget/DatePickerWidget.dart';
import 'Widget/ImageGridWidget.dart';
import 'Widget/LabeledTextField.dart';

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  const ProblemRegisterTemplate({
    Key? key,
    this.problemModel,
    required this.isEditMode,
    this.onCancel,
    this.onSubmit,
  }) : super(key: key);

  @override
  ProblemRegisterTemplateState createState() =>
      ProblemRegisterTemplateState();
}

class ProblemRegisterTemplateState extends State<ProblemRegisterTemplate> {
  late DateTime _selectedDate;
  late int? _selectedFolderId;
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final List<XFile> _problemImages = [];
  final List<XFile> _answerImages = [];
  final List<String> _existingProblemImageUrls = [];
  final List<String> _existingAnswerImageUrls = [];
  final List<String> _deletedImageUrls = []; // 삭제할 이미지 URL 추적

  @override
  void initState() {
    super.initState();
    final problemModel = widget.problemModel;
    _selectedDate = problemModel?.solvedAt ?? DateTime.now();
    if (widget.isEditMode) {
      _selectedFolderId = problemModel?.folderId;
      // 기존 이미지 URL 로드
      _existingProblemImageUrls.addAll(
        problemModel?.problemImageDataList
                ?.map((img) => img.imageUrl)
                .toList() ??
            [],
      );
      _existingAnswerImageUrls.addAll(
        problemModel?.answerImageDataList
                ?.map((img) => img.imageUrl)
                .toList() ??
            [],
      );
    } else {
      final folderProvider =
          Provider.of<FoldersProvider>(context, listen: false);
      _selectedFolderId =
          problemModel?.folderId ?? folderProvider.currentFolder?.folderId;
    }
    _titleCtrl.text = problemModel?.reference ?? '';
    _memoCtrl.text = problemModel?.memo ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePickerWidget(
                selectedDate: _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 30),
              FolderPickerWidget(
                selectedId: _selectedFolderId,
                onPicked: (id) => setState(() => _selectedFolderId = id),
              ),
              const SizedBox(height: 30),
              LabeledTextField(
                label: '제목',
                hintText: '오답노트의 제목을 작성해주세요!',
                icon: Icons.info,
                controller: _titleCtrl,
              ),
              const SizedBox(height: 30),
              LabeledTextField(
                label: '메모',
                controller: _memoCtrl,
                icon: Icons.edit,
                hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: ImageGridWidget(
                        label: '문제 이미지',
                        files: _problemImages,
                        existingImageUrls: _existingProblemImageUrls,
                        onAdd: _pickProblemImage,
                        onRemove: (i) =>
                            setState(() => _problemImages.removeAt(i)),
                        onRemoveExisting: (i) {
                          setState(() {
                            final removedUrl =
                                _existingProblemImageUrls.removeAt(i);
                            _deletedImageUrls.add(removedUrl);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: ImageGridWidget(
                        label: '해설 이미지',
                        files: _answerImages,
                        existingImageUrls: _existingAnswerImageUrls,
                        onAdd: _pickAnswerImage,
                        onRemove: (i) =>
                            setState(() => _answerImages.removeAt(i)),
                        onRemoveExisting: (i) {
                          setState(() {
                            final removedUrl =
                                _existingAnswerImageUrls.removeAt(i);
                            _deletedImageUrls.add(removedUrl);
                          });
                        },
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ImageGridWidget(
                      label: '문제 이미지',
                      files: _problemImages,
                      existingImageUrls: _existingProblemImageUrls,
                      onAdd: _pickProblemImage,
                      onRemove: (i) =>
                          setState(() => _problemImages.removeAt(i)),
                      onRemoveExisting: (i) {
                        setState(() {
                          final removedUrl =
                              _existingProblemImageUrls.removeAt(i);
                          _deletedImageUrls.add(removedUrl);
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    ImageGridWidget(
                      label: '해설 이미지',
                      files: _answerImages,
                      existingImageUrls: _existingAnswerImageUrls,
                      onAdd: _pickAnswerImage,
                      onRemove: (i) =>
                          setState(() => _answerImages.removeAt(i)),
                      onRemoveExisting: (i) {
                        setState(() {
                          final removedUrl =
                              _existingAnswerImageUrls.removeAt(i);
                          _deletedImageUrls.add(removedUrl);
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
        ));
  }

  Future<void> _pickProblemImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          setState(() => _problemImages.add(file));
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        setState(() => _problemImages.addAll(files));
      },
    );
  }

  Future<void> _pickAnswerImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(
      context,
      (XFile? file) {
        if (file != null) {
          setState(() => _answerImages.add(file));
        }
      },
      onMultipleImagesPicked: (List<XFile> files) {
        setState(() => _answerImages.addAll(files));
      },
    );
  }

  void resetAll() {
    setState(() {
      _titleCtrl.clear();
      _memoCtrl.clear();
      _problemImages.clear();
      _answerImages.clear();
    });
  }

  Future<void> submit() async {
    LoadingDialog.show(
        context, widget.isEditMode ? '오답노트 수정 중...' : '오답노트 작성 중...');
    try {
      if (widget.isEditMode) {
        await _updateProblem();
      } else {
        await _registerProblem();
      }
      showSuccessDialog(context);
    } catch (e, stackTrace) {
      log('오답노트 ${widget.isEditMode ? "수정" : "등록"} 실패: $e');
      log(stackTrace.toString());
      throw Exception(e);
    } finally {
      LoadingDialog.hide(context);
    }
  }

  /// 오답노트 등록
  Future<void> _registerProblem() async {
    log('register problem');

    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    // 1. 문제 엔티티만 먼저 등록 (이미지 없이)
    final problemRegisterModel = ProblemRegisterModel(
      problemId: null,
      memo: _memoCtrl.text,
      reference: _titleCtrl.text,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      imageDataDtoList: [], // 빈 리스트로 등록
    );

    // 서비스에서 직접 problemId 받기
    final problemService = ProblemService();
    final registeredProblemId =
        await problemService.registerProblem(problemRegisterModel);

    // Provider를 통해 문제 조회 및 상태 업데이트
    await problemsProvider.fetchProblem(registeredProblemId);
    await problemsProvider.updateProblemCount(1);
    await problemsProvider.requestReview(context);

    // 2. 폴더 갱신 (_selectedFolderId가 null이면 루트 폴더를 갱신)
    final foldersProvider = Provider.of<FoldersProvider>(context, listen: false);
    if (_selectedFolderId != null) {
      await foldersProvider.refreshFolder(_selectedFolderId!);
    } else {
      // 루트 폴더 갱신
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await foldersProvider.refreshFolder(rootFolder.folderId);
      }
    }

    // 3. 유저 정보 갱신 (경험치 업데이트)
    await Provider.of<UserProvider>(context, listen: false).fetchUserInfo();

    // 4. 화면 초기화 및 이동
    Provider.of<ScreenIndexProvider>(context, listen: false)
        .setSelectedIndex(0);

    log('problem register complete - problemId: $registeredProblemId');

    // 5. 백그라운드에서 이미지 업로드 (비동기)
    _uploadImagesInBackground(registeredProblemId, problemsProvider);

    resetAll();
  }

  /// 백그라운드에서 이미지 업로드
  void _uploadImagesInBackground(
      int problemId, ProblemsProvider problemsProvider) {
    // 이미지가 없으면 리턴
    if (_problemImages.isEmpty && _answerImages.isEmpty) {
      log('업로드할 이미지가 없음');
      return;
    }

    // 비동기로 이미지 업로드 실행 (await 없이)
    () async {
      try {
        log('백그라운드 이미지 업로드 시작 - problemId: $problemId');

        // 파일 리스트 생성
        final List<File> imageFiles = [];
        final List<String> imageTypes = [];

        // 문제 이미지 추가
        for (var xFile in _problemImages) {
          imageFiles.add(File(xFile.path));
          imageTypes.add('PROBLEM_IMAGE');
        }

        // 해설 이미지 추가
        for (var xFile in _answerImages) {
          imageFiles.add(File(xFile.path));
          imageTypes.add('ANSWER_IMAGE');
        }

        // 서버로 이미지 전송
        await problemsProvider.registerProblemImageData(
          problemId: problemId,
          problemImages: imageFiles,
          problemImageTypes: imageTypes,
        );

        log('백그라운드 이미지 업로드 완료 - problemId: $problemId');
      } catch (e, stackTrace) {
        log('백그라운드 이미지 업로드 실패 - problemId: $problemId');
        log('에러: $e');
        log('스택트레이스: $stackTrace');
        // 에러가 발생해도 사용자에게는 영향 없음 (백그라운드 작업)
      }
    }();
  }

  /// 오답노트 수정
  Future<void> _updateProblem() async {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);
    final problemId = widget.problemModel!.problemId;
    final originalFolderId = widget.problemModel!.folderId;

    // 문제 기본 정보 업데이트
    final problemRegisterModel = ProblemRegisterModel(
      problemId: problemId,
      memo: _memoCtrl.text,
      reference: _titleCtrl.text,
      solvedAt: _selectedDate,
      folderId: _selectedFolderId,
      imageDataDtoList: [],
    );

    await problemsProvider.updateProblem(problemRegisterModel);

    // 폴더 갱신 (새 폴더와 기존 폴더 모두)
    await _refreshFolders(originalFolderId);

    // 삭제할 이미지 삭제
    await _deleteRemovedImages(problemsProvider, problemId);
    // 새로 추가된 이미지 업데이트
    await _uploadAndRegisterNewImages(problemsProvider, problemId);

    resetAll();
    // 화면 초기화 및 닫기
    Navigator.of(context).pop(true);
  }

  /// 삭제된 이미지들을 서버에서 삭제
  Future<void> _deleteRemovedImages(
      ProblemsProvider problemsProvider, int problemId) async {
    if (_deletedImageUrls.isEmpty) {
      return;
    }

    for (var imageUrl in _deletedImageUrls) {
      log('이미지 삭제: $imageUrl');
      await problemsProvider.deleteProblemImageData(imageUrl);
    }

    await problemsProvider.fetchProblem(problemId);
  }

  /// 새로 추가된 이미지들을 업로드하고 서버에 등록
  Future<void> _uploadAndRegisterNewImages(
      ProblemsProvider problemsProvider, int problemId) async {
    // 이미지가 없으면 리턴
    if (_problemImages.isEmpty && _answerImages.isEmpty) {
      return;
    }

    // 파일 리스트 생성
    final List<File> imageFiles = [];
    final List<String> imageTypes = [];

    // 문제 이미지 추가
    for (var xFile in _problemImages) {
      imageFiles.add(File(xFile.path));
      imageTypes.add('PROBLEM_IMAGE');
    }

    // 해설 이미지 추가
    for (var xFile in _answerImages) {
      imageFiles.add(File(xFile.path));
      imageTypes.add('ANSWER_IMAGE');
    }

    // 서버로 직접 전송 (multipart)
    await problemsProvider.registerProblemImageData(
      problemId: problemId,
      problemImages: imageFiles,
      problemImageTypes: imageTypes,
    );
  }

  /// 폴더 컨텐츠 갱신 (수정 시 기존 폴더와 새 폴더 모두 갱신)
  Future<void> _refreshFolders(int? originalFolderId) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);

    // 새 폴더 갱신 (_selectedFolderId가 null이면 루트 폴더)
    if (_selectedFolderId != null) {
      await foldersProvider.refreshFolder(_selectedFolderId!);
    } else {
      // 루트 폴더 갱신
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await foldersProvider.refreshFolder(rootFolder.folderId);
      }
    }

    // 기존 폴더가 새 폴더와 다르면 기존 폴더도 갱신
    if (originalFolderId != null && originalFolderId != _selectedFolderId) {
      await foldersProvider.refreshFolder(originalFolderId);
    }
  }

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트가 성공적으로 저장되었습니다.",
        backgroundColor: themeProvider.primaryColor);
  }
}
