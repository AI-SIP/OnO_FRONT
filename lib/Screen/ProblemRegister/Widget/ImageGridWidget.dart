import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:provider/provider.dart';

import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Text/mobile_font_size.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ImageGridWidget extends StatelessWidget {
  final String label;
  final List<XFile> files;
  final List<String> existingImageUrls; // 기존 이미지 URL
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final ValueChanged<int>? onRemoveExisting; // 기존 이미지 삭제 콜백
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final EdgeInsetsGeometry titleIconPadding;
  final double titleIconSize;
  final double titleIconBorderRadius;
  final bool showHeader;

  const ImageGridWidget({
    Key? key,
    required this.label,
    required this.files,
    this.existingImageUrls = const [],
    required this.onAdd,
    required this.onRemove,
    this.onRemoveExisting,
    this.titleFontSize = 16,
    this.titleFontWeight = FontWeight.w500,
    this.titleIconPadding = const EdgeInsets.all(6.0),
    this.titleIconSize = 18,
    this.titleIconBorderRadius = 6.0,
    this.showHeader = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeHandler>(context);
    final totalImages = existingImageUrls.length + files.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Container(
                padding: titleIconPadding,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(titleIconBorderRadius),
                ),
                child: Icon(
                  Icons.image,
                  color: theme.primaryColor,
                  size: titleIconSize,
                ),
              ),
              const SizedBox(width: 12),
              StandardText(
                text: label,
                fontSize: MobileFontSize.reduced(context, titleFontSize),
                fontWeight: titleFontWeight,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              if (totalImages > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StandardText(
                    text: '$totalImages',
                    fontSize: 12,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 100,
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StandardText(
                          text: '추가',
                          fontSize: 12,
                          color: Colors.grey[600]!,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 기존 이미지 표시
              if (idx <= existingImageUrls.length) {
                final imageUrl = existingImageUrls[idx - 1];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImage(imagePath: imageUrl),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: DisplayImage(
                              imagePath: imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => onRemoveExisting?.call(idx - 1),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
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
                  GestureDetector(
                    onTap: () => _openLocalImage(context, file),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(file.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => onRemove(fileIdx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
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

  void _openLocalImage(BuildContext context, XFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            bottom: true,
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.file(
                    File(file.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
