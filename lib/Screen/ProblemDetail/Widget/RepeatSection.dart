import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/ProblemModel.dart';
import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/HandWriteText.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Text/UnderlinedText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Provider/ProblemsProvider.dart';

Widget buildRepeatSection(
    BuildContext ctx, ProblemModel problem, Color iconColor) {
  final list = problem.solveImageDataList ?? [];
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(Icons.menu_book, color: iconColor),
        const SizedBox(width: 8),
        HandWriteText(text: '복습 기록', fontSize: 20, color: iconColor),
      ]),
      UnderlinedText(text: '복습 횟수: ${list.length}', fontSize: 20),
    ]),
    const SizedBox(height: 10),
    ...list.asMap().entries.map((e) {
      final idx = e.key;
      final solve = e.value;
      final pid = problem.problemId;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UnderlinedText(
                text:
                    '${idx + 1}. 복습 날짜 : ${DateFormat('yyyy년 MM월 dd일').format(solve.createdAt)}',
                fontSize: 18),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) =>
                          FullScreenImage(imagePath: solve.imageUrl))),
              onLongPress: () async {
                final problemsProvider =
                    Provider.of<ProblemsProvider>(ctx, listen: false);
                final themeProvider =
                    Provider.of<ThemeHandler>(ctx, listen: false);
                final should = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => Dialog(
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
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const StandardText(
                                      text: '삭제 확인',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // 내용
                                const StandardText(
                                  text: '이 복습 이미지를 정말 삭제하시겠습니까?',
                                  fontSize: 15,
                                  color: Colors.black87,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // 액션 버튼
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          backgroundColor: Colors.grey[100],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const StandardText(
                                          text: '취소',
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const StandardText(
                                          text: '삭제',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ));
                if (should == true) {
                  await problemsProvider.deleteProblemImageData(solve.imageUrl);
                  await problemsProvider.fetchProblem(pid);
                }
              },
              child: Container(
                width: MediaQuery.of(ctx).size.width,
                height: MediaQuery.of(ctx).size.height * 0.5,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10)),
                child: DisplayImage(
                    imagePath: solve.imageUrl, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }).toList(),
  ]);
}
