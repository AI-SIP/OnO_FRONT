import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Theme/ThemeHandler.dart';
import 'ProblemDetailScreenWidget.dart';

class ProblemDetailTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  const ProblemDetailTemplate({
    required this.problemModel,
    required this.isExpanded,
    required this.onExpansionChanged,
    super.key,
  });

  @override
  State<ProblemDetailTemplate> createState() => _ProblemDetailTemplateState();
}

class _ProblemDetailTemplateState extends State<ProblemDetailTemplate> {
  final ProblemDetailScreenWidget problemDetailScreenWidget =
      ProblemDetailScreenWidget();
  final ExpansionTileController _expansionTileController = ExpansionTileController();

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
                          widget.problemModel,
                          themeProvider,
                        ),
                      ),
                      const SizedBox(width: 30.0),
                      // 오른쪽 스크롤 가능한 영역
                      Flexible(
                        flex: 1,
                        child: problemDetailScreenWidget.buildExpansionTile(
                            context, widget.problemModel, themeProvider,
                            _expansionTileController, widget.isExpanded, widget.onExpansionChanged),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    // 화면이 좁을 경우 전체를 스크롤 가능하게
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        problemDetailScreenWidget.buildCommonDetailView(
                            context, widget.problemModel, themeProvider),
                        const SizedBox(height: 30.0),
                        problemDetailScreenWidget.buildExpansionTile(
                            context, widget.problemModel, themeProvider,
                            _expansionTileController, widget.isExpanded, widget.onExpansionChanged),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

}
