import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';

class StudyRoomCreateScreen extends StatefulWidget {
  const StudyRoomCreateScreen({super.key});

  @override
  State<StudyRoomCreateScreen> createState() => _StudyRoomCreateScreenState();
}

class _StudyRoomCreateScreenState extends State<StudyRoomCreateScreen> {
  final _nameController = TextEditingController();
  final _standardStyle = const StandardText(text: '').getTextStyle();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.showError('방 이름을 입력해 주세요');
      return;
    }
    if (name.length > 20) {
      AppSnackBar.showError('방 이름은 20자 이하로 입력해 주세요');
      return;
    }

    setState(() => _isCreating = true);
    try {
      await Provider.of<StudyRoomProvider>(context, listen: false)
          .createRoom(name);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      AppSnackBar.showError('방 생성에 실패했습니다');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: SafeArea(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
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
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
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
              SizedBox(height: screenHeight * 0.01),
              StandardText(
                text: '방을 만들면 자동으로 초대 코드가 생성됩니다.',
                fontSize: 13,
                color: Colors.grey[500]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
              const Spacer(),
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
    );
  }
}
