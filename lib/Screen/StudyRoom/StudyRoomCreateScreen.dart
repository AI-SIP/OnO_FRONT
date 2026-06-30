import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Module/Image/ImagePickerHandler.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';
import 'Widget/StudyRoomThumbnail.dart';

class StudyRoomCreateScreen extends StatefulWidget {
  const StudyRoomCreateScreen({super.key});

  @override
  State<StudyRoomCreateScreen> createState() => _StudyRoomCreateScreenState();
}

class _StudyRoomCreateScreenState extends State<StudyRoomCreateScreen> {
  final _nameController = TextEditingController();
  final _standardStyle = const StandardText(text: '').getTextStyle();
  XFile? _thumbnailFile;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showValidationDialog(String message) {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const StandardText(
                      text: '필수 항목 누락',
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StandardText(
                  text: message,
                  fontSize: 14,
                  color: Colors.grey[700]!,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'PretendardLight',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await _showValidationDialog('방 이름을 입력해 주세요.');
      return;
    }
    if (name.length > 20) {
      await _showValidationDialog('방 이름은 20자 이하로 입력해 주세요.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final provider = Provider.of<StudyRoomProvider>(context, listen: false);
      final room = await provider.createRoom(name);
      final thumbnailFile = _thumbnailFile;
      if (thumbnailFile != null) {
        try {
          await provider.updateRoomThumbnail(room.roomId, thumbnailFile.path);
        } catch (_) {
          AppSnackBar.showError('방은 만들었지만 사진 등록에 실패했어요');
        }
      }
      FirebaseAnalytics.instance.logEvent(name: 'study_room_created');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      AppSnackBar.showError('방 생성에 실패했습니다');
    } finally {
      if (mounted) setState(() => _isCreating = false);
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

  void _clearThumbnail() {
    if (_isCreating || _thumbnailFile == null) return;
    setState(() => _thumbnailFile = null);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailSize = (screenWidth * 0.28).clamp(84.0, 112.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close, color: themeProvider.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: StandardText(
          text: '방 만들기',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
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
                              imagePath: _thumbnailFile?.path,
                              themeProvider: themeProvider,
                              size: thumbnailSize,
                              showEditBadge: true,
                              onTap: _isCreating ? null : _pickThumbnail,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.014),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isCreating ? null : _pickThumbnail,
                              icon: Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                                color: themeProvider.primaryColor,
                              ),
                              label: StandardText(
                                text:
                                    _thumbnailFile == null ? '사진 선택' : '사진 바꾸기',
                                fontSize: 13,
                                color: themeProvider.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_thumbnailFile != null)
                            Center(
                              child: TextButton(
                                onPressed: _clearThumbnail,
                                child: StandardText(
                                  text: '사진 선택 취소',
                                  fontSize: 12,
                                  color: Colors.grey[600]!,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'PretendardLight',
                                ),
                              ),
                            ),
                          Center(
                            child: StandardText(
                              text: '선택하지 않으면 기본 사진으로 보여요',
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
                                  Icons.group_add_outlined,
                                  color: themeProvider.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const StandardText(
                                text: '새 스터디룸 이름',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextField(
                            controller: _nameController,
                            autofocus: true,
                            maxLength: 20,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _create(),
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
                          SizedBox(height: screenHeight * 0.01),
                          StandardText(
                            text: '방을 만들면 자동으로 초대 코드가 생성됩니다.',
                            fontSize: 13,
                            color: Colors.grey[500]!,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'PretendardLight',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isCreating ? null : _create,
                      style: TextButton.styleFrom(
                        backgroundColor: _isCreating
                            ? Colors.grey[300]
                            : themeProvider.primaryColor,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.018,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const StandardText(
                              text: '방 만들기',
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
      ),
    );
  }
}
