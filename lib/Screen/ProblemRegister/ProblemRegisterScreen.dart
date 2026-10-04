import 'package:flutter/material.dart';
import '../../Module/Dialog/UnsavedChangesScope.dart';
import 'package:ono/Screen/ProblemRegister/ProblemRegisterTemplate.dart';
import 'package:ono/Screen/ProblemRegister/Widget/ActionButtons.dart';
import 'package:provider/provider.dart';

import '../../Model/Problem/ProblemModel.dart';
import '../../Util/AppAnalytics.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';

class ProblemRegisterScreen extends StatefulWidget {
  final ProblemModel? problemModel;
  final bool isEditMode;
  final int? initialFolderId;

  const ProblemRegisterScreen({
    super.key,
    required this.problemModel,
    required this.isEditMode,
    this.initialFolderId,
  });

  @override
  State<ProblemRegisterScreen> createState() => _ProblemRegisterScreenState();
}

class _ProblemRegisterScreenState extends State<ProblemRegisterScreen> {
  final GlobalKey<ProblemRegisterTemplateState> _templateKey =
      GlobalKey<ProblemRegisterTemplateState>();
  final ValueNotifier<bool> _unsavedChanges = ValueNotifier(false);

  @override
  void dispose() {
    _unsavedChanges.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AppAnalytics.logScreenView(
      widget.isEditMode ? 'ProblemEditScreen' : 'ProblemRegisterScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    return UnsavedChangesScope(
      hasChanges: _unsavedChanges,
      source: widget.isEditMode ? 'problem_edit' : 'problem_register',
      title: widget.isEditMode ? '수정을 그만둘까요?' : '작성을 그만둘까요?',
      description: widget.isEditMode
          ? '지금 나가면 고친 내용이 저장되지 않아요.'
          : '지금 나가면 쓰던 오답노트가 저장되지 않아요.',
      child: Scaffold(
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
            initialFolderId: widget.initialFolderId,
            unsavedChanges: _unsavedChanges,
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
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: ActionButtons(
            isEdit: widget.isEditMode,
            onCancel: () => _templateKey.currentState?.resetAll(),
            onSubmit: () => _templateKey.currentState?.submit(),
          ),
        ),
      ),
    );
  }
}
