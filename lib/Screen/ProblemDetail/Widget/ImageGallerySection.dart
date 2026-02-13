import 'package:flutter/material.dart';
import 'package:ono/Module/Text/HandWriteText.dart';

import '../../../Module/Image/DisplayImage.dart';
import '../../../Module/Image/FullScreenImage.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class ImageGallerySection extends StatefulWidget {
  final List<String> imageUrls;
  final String label;
  final Color color;
  final ThemeHandler themeProvider;

  const ImageGallerySection({
    super.key,
    required this.imageUrls,
    required this.label,
    required this.color,
    required this.themeProvider,
  });

  @override
  State<ImageGallerySection> createState() => _ImageGallerySectionState();
}

class _ImageGallerySectionState extends State<ImageGallerySection> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 화면 크기에 따른 이미지 높이 계산
    double imageHeight;
    if (screenWidth > 600) {
      // 태블릿: 화면 높이의 40%로 제한 (최대 500)
      imageHeight = (screenHeight * 0.6).clamp(300.0, 500.0);
    } else {
      // 모바일: 화면 너비의 90%
      imageHeight = screenWidth * 0.9;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PageView - 더 큰 이미지
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
              color: widget.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10)),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImage(imagePath: widget.imageUrls[i]),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DisplayImage(
                    imagePath: widget.imageUrls[i],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // 도트 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _current == i ? 12 : 8,
              height: _current == i ? 12 : 8,
              decoration: BoxDecoration(
                color: _current == i
                    ? widget.themeProvider.primaryColor
                    : widget.themeProvider.primaryColor.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}
