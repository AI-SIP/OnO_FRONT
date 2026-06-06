import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';
import '../../Provider/StudyRoomProvider.dart';
import '../../Util/AppSnackBar.dart';

class StudyRoomJoinScreen extends StatefulWidget {
  const StudyRoomJoinScreen({super.key});

  @override
  State<StudyRoomJoinScreen> createState() => _StudyRoomJoinScreenState();
}

class _StudyRoomJoinScreenState extends State<StudyRoomJoinScreen> {
  final _codeController = TextEditingController();
  final _standardStyle = const StandardText(text: '').getTextStyle();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_isJoining) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      AppSnackBar.showError('6자리 숫자를 입력해 주세요');
      return;
    }

    setState(() => _isJoining = true);
    try {
      await Provider.of<StudyRoomProvider>(context, listen: false)
          .joinRoom(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppSnackBar.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isJoining = false);
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
          text: '코드로 참여하기',
          fontSize: 18,
          color: themeProvider.primaryColor,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.06,
            screenHeight * 0.05,
            screenWidth * 0.06,
            screenHeight * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.group_add_outlined,
                  size: 40,
                  color: themeProvider.primaryColor,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              StandardText(
                text: '초대 코드를 입력하세요',
                fontSize: 20,
                color: themeProvider.primaryColor,
              ),
              SizedBox(height: screenHeight * 0.01),
              StandardText(
                text: '친구에게 받은 6자리 숫자 코드를 입력해 주세요.',
                fontSize: 14,
                color: Colors.grey[500]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _join(),
                onChanged: (v) {
                  if (v.length == 6) _join();
                },
                style: _standardStyle.copyWith(
                  fontSize: 30,
                  letterSpacing: 10,
                  color: themeProvider.darkPrimaryColor,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: _standardStyle.copyWith(
                    fontSize: 30,
                    letterSpacing: 10,
                    color: Colors.grey[300],
                  ),
                  fillColor: Colors.grey[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: themeProvider.primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              StandardText(
                text: '※ 체험용 코드: 123456',
                fontSize: 12,
                color: Colors.grey[400]!,
                fontWeight: FontWeight.normal,
                fontFamily: 'PretendardLight',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isJoining ? null : _join,
                  style: TextButton.styleFrom(
                    backgroundColor: _isJoining
                        ? Colors.grey[300]
                        : themeProvider.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const StandardText(
                          text: '참여하기',
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
