import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:provider/provider.dart';

import '../../Model/Common/ProblemImageDataType.dart';
import '../../Model/Problem/ProblemImageDataRegisterModel.dart';
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
import '../../Service/Api/FileUpload/FileUploadService.dart';
import 'Widget/ActionButtons.dart';
import 'Widget/DatePickerWidget.dart';
import 'Widget/ImageGridWidget.dart';
import 'Widget/LabledTextField.dart';

class ProblemRegisterTemplate extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterTemplate({
    Key? key,
    this.problemModel,
    required this.isEditMode,
  }) : super(key: key);

  @override
  _ProblemRegisterTemplateState createState() =>
      _ProblemRegisterTemplateState();
}

class _ProblemRegisterTemplateState extends State<ProblemRegisterTemplate> {
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
        problemModel?.problemImageDataList?.map((img) => img.imageUrl).toList() ?? [],
      );
      _existingAnswerImageUrls.addAll(
        problemModel?.answerImageDataList?.map((img) => img.imageUrl).toList() ?? [],
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
                            final removedUrl = _existingProblemImageUrls.removeAt(i);
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
                            final removedUrl = _existingAnswerImageUrls.removeAt(i);
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
                          final removedUrl = _existingProblemImageUrls.removeAt(i);
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
                          final removedUrl = _existingAnswerImageUrls.removeAt(i);
                          _deletedImageUrls.add(removedUrl);
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              ActionButtons(
                isEdit: widget.isEditMode,
                onCancel: _resetAll,
                onSubmit: _submit,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ));
  }

  Future<void> _pickProblemImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(context, (XFile? file) {
      if (file != null) {
        setState(() => _problemImages.add(file));
      }
    });
  }

  Future<void> _pickAnswerImage() async {
    final imagePicker = ImagePickerHandler();
    imagePicker.showImagePicker(context, (XFile? file) {
      if (file != null) {
        setState(() => _answerImages.add(file));
      }
    });
  }

  void _resetAll() {
    setState(() {
      _titleCtrl.clear();
      _memoCtrl.clear();
      _problemImages.clear();
      _answerImages.clear();
    });
  }

  Future<void> _submit() async {
    LoadingDialog.show(context, widget.isEditMode ? '오답노트 수정 중...' : '오답노트 작성 중...');
    try {
      final service = FileUploadService();
      final problemsProvider = Provider.of<ProblemsProvider>(context, listen: false);

      if (widget.isEditMode) {
        // ===== 수정 모드 =====
        log('오답노트 수정 시작');

        // 1. 삭제할 이미지들 삭제
        for (var imageUrl in _deletedImageUrls) {
          log('이미지 삭제: $imageUrl');
          await problemsProvider.deleteProblemImageData(imageUrl);
        }

        // 2. 새로 추가할 이미지 업로드 및 등록
        final problemImageUrlList =
            await service.uploadMultipleImageFiles(_problemImages);
        final answerImageUrlList =
            await service.uploadMultipleImageFiles(_answerImages);

        // 새 문제 이미지 등록
        for (var imageUrl in problemImageUrlList) {
          log('문제 이미지 추가: $imageUrl');
          final problemImageDataRegisterModel = ProblemImageDataRegisterModel(
            problemId: widget.problemModel!.problemId,
            imageUrl: imageUrl,
            problemImageType: ProblemImageType.PROBLEM_IMAGE,
          );
          await problemsProvider.registerProblemImageData(problemImageDataRegisterModel);
        }

        // 새 해설 이미지 등록
        for (var imageUrl in answerImageUrlList) {
          log('해설 이미지 추가: $imageUrl');
          final answerImageDataRegisterModel = ProblemImageDataRegisterModel(
            problemId: widget.problemModel!.problemId,
            imageUrl: imageUrl,
            problemImageType: ProblemImageType.ANSWER_IMAGE,
          );
          await problemsProvider.registerProblemImageData(answerImageDataRegisterModel);
        }

        // 3. 문제 기본 정보 업데이트 (제목, 메모, 날짜, 폴더)
        final problemRegisterModel = ProblemRegisterModel(
          problemId: widget.problemModel!.problemId,
          memo: _memoCtrl.text,
          reference: _titleCtrl.text,
          solvedAt: _selectedDate,
          folderId: _selectedFolderId,
          imageDataDtoList: [], // 이미지는 별도로 처리했으므로 빈 리스트
        );

        await problemsProvider.updateProblem(problemRegisterModel);

        // 폴더 컨텐츠 갱신
        if (problemRegisterModel.folderId != null) {
          await Provider.of<FoldersProvider>(context, listen: false)
              .fetchFolderContent(problemRegisterModel.folderId);
        }

        await Provider.of<FoldersProvider>(context, listen: false)
            .fetchFolderContent(widget.problemModel!.folderId);

        _resetAll();
        Navigator.of(context).pop(true);
      } else {
        // ===== 등록 모드 =====
        final problemImageUrlList =
            await service.uploadMultipleImageFiles(_problemImages);
        final answerImageUrlList =
            await service.uploadMultipleImageFiles(_answerImages);

        final List<ProblemImageDataRegisterModel> imageDataList = [];

        for (var imageUrl in problemImageUrlList) {
          imageDataList.add(ProblemImageDataRegisterModel(
            problemId: null,
            imageUrl: imageUrl,
            problemImageType: ProblemImageType.PROBLEM_IMAGE,
          ));
        }

        for (var imageUrl in answerImageUrlList) {
          imageDataList.add(ProblemImageDataRegisterModel(
            problemId: null,
            imageUrl: imageUrl,
            problemImageType: ProblemImageType.ANSWER_IMAGE,
          ));
        }

        final problemRegisterModel = ProblemRegisterModel(
          problemId: null,
          memo: _memoCtrl.text,
          reference: _titleCtrl.text,
          solvedAt: _selectedDate,
          folderId: _selectedFolderId,
          imageDataDtoList: imageDataList,
        );

        await problemsProvider.registerProblem(problemRegisterModel, context);

        await Provider.of<FoldersProvider>(context, listen: false)
            .fetchFolderContent(_selectedFolderId);

        // 오답노트 작성 시 유저 정보 갱신 (경험치 업데이트)
        await Provider.of<UserProvider>(context, listen: false)
            .fetchUserInfo();

        _resetAll();

        Provider.of<ScreenIndexProvider>(context, listen: false)
            .setSelectedIndex(0);
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

  void showSuccessDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    SnackBarDialog.showSnackBar(
        context: context,
        message: "오답노트가 성공적으로 저장되었습니다.",
        backgroundColor: themeProvider.primaryColor);
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const StandardText(
          text: '로그인 필요',
        ),
        content: const StandardText(
          text: '오답노트를 작성하려면 로그인 해주세요!',
        ),
        actions: <Widget>[
          TextButton(
            child: const StandardText(
              text: '확인',
              fontSize: 20,
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // 다이얼로그 닫기
            },
          )
        ],
      ),
    );
  }
}
