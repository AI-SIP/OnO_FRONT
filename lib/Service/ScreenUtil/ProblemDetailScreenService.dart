import 'package:flutter/material.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterScreenV2.dart';
import 'package:provider/provider.dart';

import '../../GlobalModule/Theme/SnackBarDialog.dart';
import '../../GlobalModule/Theme/StandardText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemModel.dart';

class ProblemDetailScreenService {
  Future<ProblemModel?> fetchProblemDetails(
      BuildContext context, int? problemId) async {
    return Provider.of<FoldersProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }

  void deleteProblem(BuildContext context, int? problemId, Function onSuccess,
      Function onError) {
    if (problemId == null) {
      SnackBarDialog.showSnackBar(context: context, message: "오답노트를 불러오는 과정에서 오류가 발생했습니다.", backgroundColor: Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

        return AlertDialog(
          backgroundColor: Colors.white,
          title: StandardText(
              text: '오답노트 삭제', fontSize: 16, color: themeProvider.primaryColor),
          content: StandardText(
              text: '정말로 이 오답노트를 삭제하시겠습니까?',
              fontSize: 14,
              color: themeProvider.primaryColor),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const StandardText(
                text: '취소',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Provider.of<FoldersProvider>(context, listen: false)
                    .deleteProblem(problemId)
                    .then((success) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  if (success) {
                    onSuccess();
                  } else {
                    onError('오답노트 삭제에 실패했습니다.');
                  }
                }).catchError((error) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  onError('오류 발생: ${error.toString()}');
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
}
