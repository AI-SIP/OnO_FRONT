import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/Problem/ProblemModelWithTemplate.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../ProblemDetailScreenWidget.dart';

class SpecialProblemDetailTemplate extends StatelessWidget {
  final ProblemModelWithTemplate problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget =
      ProblemDetailScreenWidget();

  SpecialProblemDetailTemplate({required this.problemModel, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        problemDetailScreenWidget.buildBackground(themeProvider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: Container(
            constraints: BoxConstraints(maxWidth: screenWidth),
            child: screenWidth > 600
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽 고정 영역
                      Flexible(
                        flex: 1,
                        child: problemDetailScreenWidget.buildCommonDetailView(
                            context,
                            problemModel,
                            themeProvider,
                            problemModel.templateType!),
                      ),
                      const SizedBox(width: 30.0),
                      // 오른쪽 스크롤 가능한 영역
                      Flexible(
                        flex: 1,
                        child: problemDetailScreenWidget.buildExpansionTile(
                            context,
                            problemModel,
                            themeProvider,
                            problemModel.templateType!),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    // 화면이 좁을 경우 전체를 스크롤 가능하게
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        problemDetailScreenWidget.buildCommonDetailView(
                          context,
                          problemModel,
                          themeProvider,
                          problemModel.templateType!,
                        ),
                        const SizedBox(height: 30.0),
                        problemDetailScreenWidget.buildExpansionTile(
                          context,
                          problemModel,
                          themeProvider,
                          problemModel.templateType!,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
