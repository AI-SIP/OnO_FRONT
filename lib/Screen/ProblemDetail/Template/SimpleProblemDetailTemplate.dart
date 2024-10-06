
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../GlobalModule/Theme/ThemeHandler.dart';
import '../../../Model/ProblemModel.dart';
import '../ProblemDetailScreenWidget.dart';

class SimpleProblemDetailTemplate extends StatelessWidget {
  final ProblemModel problemModel;
  final ProblemDetailScreenWidget problemDetailScreenWidget = ProblemDetailScreenWidget();

  SimpleProblemDetailTemplate({required this.problemModel, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        problemDetailScreenWidget.buildBackground(themeProvider),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  problemDetailScreenWidget.buildCommonDetailView(context, problemModel, themeProvider, problemModel.templateType!),
                  problemDetailScreenWidget.buildAnalysisExpansionTile(context, problemModel, themeProvider, problemModel.templateType!),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
