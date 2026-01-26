import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:provider/provider.dart';

import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ImageGridWidget extends StatelessWidget {
  final String label;
  final List<XFile> files;
  final List<String> existingImageUrls; // 기존 이미지 URL
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int>? onRemoveExisting; // 기존 이미지 삭제 콜백

  const ImageGridWidget({
    Key? key,
    required this.label,
    required this.files,
    this.existingImageUrls = const [],
    required this.onAdd,
    required this.onRemove,
    this.onRemoveExisting,
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
            itemCount: existingImageUrls.length + files.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, idx) {
              // 첫 번째 아이템: 추가 버튼
              if (idx == 0) {
                return GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: theme.primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: theme.primaryColor),
                  ),
                );
              }

              // 기존 이미지 표시
              if (idx <= existingImageUrls.length) {
                final imageUrl = existingImageUrls[idx - 1];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: DisplayImage(
                          imagePath: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveExisting?.call(idx - 1),
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
              }

              // 새로 추가된 로컬 파일 표시
              final fileIdx = idx - existingImageUrls.length - 1;
              final file = files[fileIdx];
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
                      onTap: () => onRemove(fileIdx),
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
