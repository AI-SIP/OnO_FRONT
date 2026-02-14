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
    final screenWidth = MediaQuery.of(context).size.width;
    final selectorWidth = screenWidth >= 600 ? 210.0 : 170.0;

    // 폴더 데이터가 로드될 때까지 기다림
    if (foldersProvider.folders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: StandardText(
                text: '공책 선택',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    final name = FolderPickerDialog.getFolderNameByFolderId(widget.selectedId);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: StandardText(
              text: '공책 선택',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(
            width: selectorWidth,
            child: GestureDetector(
              onTap: () async {
                final id = await FolderPickerWidget.showPicker(
                    context, widget.selectedId);
                widget.onPicked(id);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StandardText(
                          text: name ?? '책장',
                          fontSize: 14,
                          color: Colors.black87,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
