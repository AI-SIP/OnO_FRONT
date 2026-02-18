import 'package:flutter/material.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Theme/GridPainter.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'Widget/AnalysisSection.dart';
import 'Widget/DateRowWidget.dart';
import 'Widget/ImageSection.dart';
import 'Widget/LayoutHelpers.dart';
import 'Widget/RepeatSection.dart';

class ProblemDetailScreenWidget {
  Widget buildBackground(ThemeHandler theme) => CustomPaint(
        size: Size.infinite,
        painter: GridPainter(gridColor: theme.primaryColor, isSpring: true),
      );

  Widget buildCommonDetailView(
          BuildContext ctx, ProblemModel problem, ThemeHandler theme) =>
      withPadding(
        ctx,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            verticalSpacer(ctx, .03),
            buildDateRow(problem.solvedAt!, theme.primaryColor),
            /*
            verticalSpacer(ctx, .03),
            buildReferenceRow(problem.reference, theme.primaryColor),

             */
            verticalSpacer(ctx, .03),
            buildImageSection(
                ctx,
                problem.problemImageDataList?.map((m) => m.imageUrl).toList() ??
                    [],
                '문제 이미지',
                theme),
          ],
        ),
      );

  Widget buildExpansionTile(
          BuildContext ctx,
          ProblemModel problem,
          ThemeHandler theme,
          ExpansionTileController controller,
          bool isExpanded,
          Function(bool) onExpansionChanged) =>
      SingleChildScrollView(
        child: ExpansionTile(
          controller: controller,
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          title: tileTitle('정답 확인', Colors.black),
          children: [
            verticalSpacer(ctx, .03),
            buildMemoSection(problem.memo, theme.primaryColor),
            verticalSpacer(ctx, .04),
            buildImageSection(
                ctx,
                problem.answerImageDataList?.map((m) => m.imageUrl).toList() ??
                    [],
                '해설 이미지',
                theme),
            verticalSpacer(ctx, .04),
            buildAnalysisSection(ctx, problem.analysis, theme.primaryColor),
            verticalSpacer(ctx, .04),
            buildRepeatSection(ctx, problem, theme.primaryColor),
            verticalSpacer(ctx, .03),
          ],
        ),
      );
}
