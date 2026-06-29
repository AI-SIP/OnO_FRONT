import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Model/StudyRoom/StudyRoomModel.dart';
import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';
import 'Widget/StudyRoomThumbnail.dart';

class StudyRoomEditScreen extends StatefulWidget {
  final StudyRoomModel room;

  const StudyRoomEditScreen({super.key, required this.room});

  @override
  State<StudyRoomEditScreen> createState() => _StudyRoomEditScreenState();
}

class _StudyRoomEditScreenState extends State<StudyRoomEditScreen> {
  late final TextEditingController _nameController;
  final _standardStyle = const StandardText(text: '').getTextStyle();
  XFile? _thumbnailFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _nameChanged => _nameController.text.trim() != widget.room.name;

  bool get _thumbnailChanged => _thumbnailFile != null;

  bool get _hasChanges => _nameChanged || _thumbnailChanged;

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showError('방 이름을 입력해 주세요');
      return;
    }
    if (name.length > 20) {
      AppSnackBar.showError('방 이름은 20자 이하로 입력해 주세요');
      return;
    }
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final provider = Provider.of<StudyRoomProvider>(context, listen: false);
    bool nameSuccess = !_nameChanged;
    bool thumbnailSuccess = !_thumbnailChanged;

    if (_nameChanged) {
      try {
        await provider.updateRoomName(widget.room.roomId, name);
        nameSuccess = true;
      } catch (_) {}
    }

    if (_thumbnailChanged) {
      try {
        await provider.updateRoomThumbnail(
            widget.room.roomId, _thumbnailFile!.path);
        thumbnailSuccess = true;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (nameSuccess && thumbnailSuccess) {
      Navigator.pop(context, true);
    } else if (!nameSuccess && !thumbnailSuccess) {
      AppSnackBar.showError('수정에 실패했습니다. 다시 시도해 주세요');
    } else if (!nameSuccess) {
      AppSnackBar.showError('사진은 변경됐지만 이름 수정에 실패했어요');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.showError('이름은 변경됐지만 사진 수정에 실패했어요');
      Navigator.pop(context, true);
    }
  }

  void _pickThumbnail() {
    ImagePickerHandler().showImagePicker(
      context,
      (XFile? file) {
        if (file == null || !mounted) return;
        setState(() => _thumbnailFile = file);
      },
    );
  }

  void _clearPickedThumbnail() {
    if (_isSaving || _thumbnailFile == null) return;
    setState(() => _thumbnailFile = null);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailSize = (screenWidth * 0.28).clamp(84.0, 112.0).toDouble();

    final currentImagePath =
        _thumbnailFile?.path ?? widget.room.thumbnailImagePath;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: themeProvider.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: StandardText(
          text: '스터디룸 정보 수정',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                screenHeight * 0.04,
                screenWidth * 0.06,
                screenHeight * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: StudyRoomThumbnail(
                              imagePath: currentImagePath,
                              themeProvider: themeProvider,
                              size: thumbnailSize,
                              showEditBadge: true,
                              onTap: _isSaving ? null : _pickThumbnail,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.014),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isSaving ? null : _pickThumbnail,
                              icon: Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                                color: themeProvider.primaryColor,
                              ),
                              label: StandardText(
                                text: _thumbnailChanged ? '사진 바꾸기' : '사진 변경',
                                fontSize: 13,
                                color: themeProvider.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_thumbnailChanged)
                            Center(
                              child: TextButton(
                                onPressed: _clearPickedThumbnail,
                                child: StandardText(
                                  text: '새 사진 선택 취소',
                                  fontSize: 12,
                                  color: Colors.grey[600]!,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'PretendardLight',
                                ),
                              ),
                            ),
                          Center(
                            child: StandardText(
                              text: _thumbnailChanged
                                  ? '저장 전까지 기존 사진으로 되돌릴 수 있어요'
                                  : '사진과 이름을 함께 수정할 수 있어요',
                              fontSize: 12,
                              color: Colors.grey[500]!,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'PretendardLight',
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.035),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: themeProvider.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const StandardText(
                                text: '스터디룸 이름',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextField(
                            controller: _nameController,
                            maxLength: 20,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                            style: _standardStyle.copyWith(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: '예) 수능 준비방, 영어 스터디',
                              hintStyle: _standardStyle.copyWith(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              fillColor: Colors.grey[50],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor
                                      .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving ? null : _save,
                      style: TextButton.styleFrom(
                        backgroundColor: _isSaving
                            ? Colors.grey[300]
                            : themeProvider.primaryColor,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.018,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const StandardText(
                              text: '저장',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
