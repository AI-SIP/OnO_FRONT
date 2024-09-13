import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../GlobalModule/Theme/DecorateText.dart';
import '../../GlobalModule/Theme/ThemeHandler.dart';
import '../../Model/ProblemModel.dart';
import '../../Screen/ProblemRegisterScreen.dart';

class ProblemDetailScreenService {
  Future<ProblemModel?> fetchProblemDetails(
      BuildContext context, int? problemId) async {
    return Provider.of<FoldersProvider>(context, listen: false)
        .getProblemDetails(problemId);
  }

  void refreshProblemDetails(
      BuildContext context, Future<ProblemModel?> Function() fetchDetails) {
    fetchDetails();
  }

  void editProblem(BuildContext context, int? problemId) async {
    if (problemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제 ID가 유효하지 않습니다.')),
      );
      return;
    }

    ProblemModel? problem =
        await Provider.of<FoldersProvider>(context, listen: false)
            .getProblemDetails(problemId);

    if (problem != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProblemRegisterScreen(
            problem: problem,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제를 불러오는 데 실패했습니다.')),
      );
    }
  }

  void deleteProblem(BuildContext context, int? problemId, Function onSuccess,
      Function onError) {
    if (problemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문제 ID가 유효하지 않습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

        return AlertDialog(
          title: DecorateText(
              text: '문제 삭제', fontSize: 24, color: themeProvider.primaryColor),
          content: DecorateText(
              text: '정말로 이 문제를 삭제하시겠습니까?',
              fontSize: 20,
              color: themeProvider.primaryColor),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
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
                    onError('문제 삭제에 실패했습니다.');
                  }
                }).catchError((error) {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  onError('오류 발생: ${error.toString()}');
                });
              },
              child: const DecorateText(
                text: '삭제',
                fontSize: 20,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}
