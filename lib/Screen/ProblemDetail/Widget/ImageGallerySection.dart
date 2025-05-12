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
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Row(
          children: [
            Icon(Icons.camera_alt, color: widget.color),
            const SizedBox(width: 8),
            HandWriteText(
                text: widget.label, fontSize: 20, color: widget.color),
          ],
        ),
        const SizedBox(height: 8),
        // PageView
        SizedBox(
          height: width * 0.75, // 가로 넓이에 비례한 높이
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
