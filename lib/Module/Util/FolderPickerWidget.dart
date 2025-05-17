import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import '../../../Module/Util/FolderPickerDialog.dart';

class FolderPickerWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    final name = FolderPickerDialog.getFolderNameByFolderId(selectedId);
    return Row(
      children: [
        Icon(Icons.menu_book_outlined, color: theme.primaryColor),
        const SizedBox(width: 6),
        StandardText(text: '공책 선택', fontSize: 16, color: theme.primaryColor),
        const Spacer(),
        TextButton(
          onPressed: () async {
            final id = await showPicker(context, selectedId);
            onPicked(id);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: theme.primaryColor.withOpacity(0.1),
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
