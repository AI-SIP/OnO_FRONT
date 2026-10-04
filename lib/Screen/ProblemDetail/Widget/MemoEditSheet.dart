import 'package:flutter/material.dart';

import '../../../Model/Problem/ProblemRegisterModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Text/StandardText.dart';

/// 오답노트 상세에서 메모만 바로 쓰는 시트.
///
/// 저장을 누르면 앞뒤 공백을 지운 글을 돌려주고, 닫으면 null 이다. 서버가 빈
/// 메모를 무시해서 지울 수는 없으므로, 비어 있으면 저장 버튼을 막는다.
Future<String?> showMemoEditSheet(
  BuildContext context, {
  required String initialMemo,
  required Color color,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MemoEditSheet(initialMemo: initialMemo, color: color),
  );
}

class _MemoEditSheet extends StatefulWidget {
  final String initialMemo;
  final Color color;

  const _MemoEditSheet({required this.initialMemo, required this.color});

  @override
  State<_MemoEditSheet> createState() => _MemoEditSheetState();
}

class _MemoEditSheetState extends State<_MemoEditSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialMemo);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave {
    final text = _controller.text.trim();
    return text.isNotEmpty && text != widget.initialMemo.trim();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StandardText(
                text: widget.initialMemo.isEmpty ? '메모 추가' : '메모 고치기',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                maxLength: ProblemRegisterModel.memoMaxLength,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '왜 틀렸는지, 다음엔 무엇부터 볼지 적어 두세요',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: BorderSide(color: widget.color),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSave
                      ? () => Navigator.pop(context, _controller.text.trim())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: StandardText(
                    text: '저장',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _canSave ? Colors.white : Colors.grey[600]!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
