import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Module/Util/FolderPickerDialog.dart';
import '../../../Provider/FoldersProvider.dart';

class FolderPickerWidget extends StatefulWidget {
  final int? selectedId;
  final ValueChanged<int?> onPicked;

  const FolderPickerWidget({
    Key? key,
    this.selectedId,
    required this.onPicked,
  }) : super(key: key);

  static Future<int?> showPicker(BuildContext ctx, int? current) {
    return showDialog<int>(
      context: ctx,
      builder: (_) => FolderPickerDialog(initialFolderId: current),
    );
  }

  @override
  State<FolderPickerWidget> createState() => _FolderPickerWidgetState();
}

class _FolderPickerWidgetState extends State<FolderPickerWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    final foldersProvider = Provider.of<FoldersProvider>(context);

    // 폴더 데이터가 로드될 때까지 기다림
    if (foldersProvider.folders.isEmpty) {
      return Row(
        children: [
          Icon(Icons.menu_book_outlined, color: theme.primaryColor),
          const SizedBox(width: 6),
          StandardText(text: '공책 선택', fontSize: 16, color: theme.primaryColor),
          const Spacer(),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    final name = FolderPickerDialog.getFolderNameByFolderId(widget.selectedId);
    return Row(
      children: [
        Icon(Icons.menu_book_outlined, color: theme.primaryColor),
        const SizedBox(width: 6),
        StandardText(text: '공책 선택', fontSize: 16, color: theme.primaryColor),
        const Spacer(),
        TextButton(
          onPressed: () async {
            final id = await FolderPickerWidget.showPicker(context, widget.selectedId);
            widget.onPicked(id);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: Colors.white,
            side: BorderSide(color: theme.primaryColor, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_open, color: theme.primaryColor),
              const SizedBox(width: 8),
              StandardText(
                text: name ?? '책장',
                fontSize: 14,
                color: theme.primaryColor,
              ),
            ],
          ),
        )
      ],
    );
  }
}
