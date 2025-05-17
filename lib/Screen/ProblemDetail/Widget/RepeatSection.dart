import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/ProblemModel.dart';
import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/HandWriteText.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Text/UnderlinedText.dart';
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
                final prov = Provider.of<ProblemsProvider>(ctx, listen: false);
                final should = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => AlertDialog(
                          title: const StandardText(text: '삭제 확인'),
                          content: const StandardText(
                              text: '이 복습 이미지를 정말 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const StandardText(text: '취소')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const StandardText(
                                    text: '삭제', color: Colors.red)),
                          ],
                        ));
                if (should == true) {
                  await prov.deleteProblemImageData(solve.imageUrl);
                  await prov.fetchProblem(pid);
                }
              },
              child: Container(
                width: MediaQuery.of(ctx).size.width,
                height: MediaQuery.of(ctx).size.height * 0.5,
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
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
