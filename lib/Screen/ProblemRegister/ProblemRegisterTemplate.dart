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
import '../../Module/Text/StandardText.dart';
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
  ProblemRegisterTemplateState createState() => ProblemRegisterTemplateState();
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
    final spacing = isWide ? 50.0 : 30.0; // 태블릿: 50px, 모바일: 30px

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
              SizedBox(height: spacing),
              FolderPickerWidget(
                selectedId: _selectedFolderId,
                onPicked: (id) => setState(() => _selectedFolderId = id),
              ),
              SizedBox(height: spacing),
              LabeledTextField(
                label: '제목',
                hintText: '오답노트의 제목을 작성해주세요!',
                icon: Icons.info,
                controller: _titleCtrl,
              ),
              SizedBox(height: spacing),
              LabeledTextField(
                label: '메모',
                controller: _memoCtrl,
                icon: Icons.edit,
                hintText: '기록하고 싶은 내용을 간단하게 작성해주세요!',
                maxLines: 3,
              ),
              SizedBox(height: spacing),
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
    // 제목 필수 입력 검증
    if (_titleCtrl.text.trim().isEmpty) {
      _showTitleRequiredDialog(context);
      return;
    }

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

  void _showTitleRequiredDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                        Icons.warning_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '경고',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 내용
                const StandardText(
                  text: '제목을 입력해 주세요!',
                  fontSize: 15,
                  color: Colors.black87,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 액션 버튼
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      backgroundColor: themeProvider.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const StandardText(
                      text: '확인',
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    // 2. 유저 정보 갱신 (경험치 업데이트)
    await Provider.of<UserProvider>(context, listen: false).fetchUserInfo();

    // 3. 폴더 갱신 (화면 전환 전에 먼저 캐시 삭제 및 타임스탬프 업데이트)
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    if (_selectedFolderId != null) {
      await foldersProvider.refreshFolder(_selectedFolderId!);
    } else {
      // 루트 폴더 갱신 (타임스탬프 업데이트됨)
      final rootFolder = foldersProvider.rootFolder;
      if (rootFolder != null) {
        await foldersProvider.refreshFolder(rootFolder.folderId);
      }
    }

    // 4. 화면 초기화 및 이동 (이제 DirectoryScreen이 mount되면서 변경된 타임스탬프를 감지)
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
    // 비동기로 이미지 업로드 실행 (await 없이)
    () async {
      try {
        log('백그라운드 이미지 업로드 시작 - problemId: $problemId');

        // 이미지가 없으면 리턴
        if (_problemImages.isEmpty && _answerImages.isEmpty) {
          await problemsProvider.updateProblemAnalysisStatus(
              problemId: problemId);
          log('업로드할 이미지가 없음');
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

        // 서버로 이미지 전송
        await problemsProvider.registerProblemImageData(
          problemId: problemId,
          problemImages: imageFiles,
          problemImageTypes: imageTypes,
        );

        log('백그라운드 이미지 업로드 완료 - problemId: $problemId');

        // 이미지 업로드 완료 후 폴더 캐시 새로고침 (썸네일 업데이트)
        if (mounted) {
          final foldersProvider =
              Provider.of<FoldersProvider>(context, listen: false);
          if (_selectedFolderId != null) {
            await foldersProvider.refreshFolder(_selectedFolderId!);
          } else {
            // 루트 폴더 갱신 (타임스탬프 업데이트됨)
            final rootFolder = foldersProvider.rootFolder;
            if (rootFolder != null) {
              await foldersProvider.refreshFolder(rootFolder.folderId);
            }
          }
          log('폴더 캐시 새로고침 완료 - 썸네일 업데이트됨');
        }
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
