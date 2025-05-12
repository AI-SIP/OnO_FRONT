import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:provider/provider.dart';

import '../../../Module/Theme/ThemeHandler.dart';

class ImageGridWidget extends StatelessWidget {
  final String label;
  final List<XFile> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const ImageGridWidget({
    Key? key,
    required this.label,
    required this.files,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: theme.primaryColor),
            const SizedBox(width: 6),
            StandardText(text: label, color: theme.primaryColor),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: files.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, idx) {
              if (idx == 0) {
                return GestureDetector(
                  onTap: onAdd, // parent will call ImagePickerHandler here
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      border: Border.all(color: theme.primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: theme.primaryColor),
                  ),
                );
              }
              final file = files[idx - 1];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(file.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(idx - 1),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
