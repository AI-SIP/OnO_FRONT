import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'ProblemDetailScreenWidget.dart';

class ProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget =
      ProblemDetailScreenWidget();

  ProblemDetailTemplate({required this.problemModel, super.key});

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
                        ),
                      ),
                      const SizedBox(width: 30.0),
                      // 오른쪽 스크롤 가능한 영역
                      Flexible(
                        flex: 1,
                        child: problemDetailScreenWidget.buildExpansionTile(
                            context, problemModel, themeProvider),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    // 화면이 좁을 경우 전체를 스크롤 가능하게
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        problemDetailScreenWidget.buildCommonDetailView(
                            context, problemModel, themeProvider),
                        const SizedBox(height: 30.0),
                        problemDetailScreenWidget.buildExpansionTile(
                            context, problemModel, themeProvider),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
