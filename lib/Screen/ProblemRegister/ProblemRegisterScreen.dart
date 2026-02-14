import 'package:flutter/material.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';
import 'package:ono/Screen/ProblemRegister/Widget/ActionButtons.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';

class ProblemRegisterScreen extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;

  const ProblemRegisterScreen({
    super.key,
    required this.problemModel,
    required this.isEditMode,
  });

  @override
  State<ProblemRegisterScreen> createState() => _ProblemRegisterScreenState();
}

class _ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  final GlobalKey<ProblemRegisterTemplateState> _templateKey =
      GlobalKey<ProblemRegisterTemplateState>();

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: StandardText(
          text: widget.isEditMode ? '오답노트 수정' : '오답노트 작성',
          color: theme.primaryColor,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ProblemRegisterTemplate(
          key: _templateKey,
          problemModel: widget.problemModel,
          isEditMode: widget.isEditMode,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: ActionButtons(
          isEdit: widget.isEditMode,
          onCancel: () => _templateKey.currentState?.resetAll(),
          onSubmit: () => _templateKey.currentState?.submit(),
        ),
      ),
    );
  }
}
