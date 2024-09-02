import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../Theme/ThemeHandler.dart';
import 'FindPixelColor.dart';
import 'PickerResponse.dart';

class ColorPicker extends StatefulWidget {
  final Widget child;
  final Widget? trackerImage;
  final bool? showMarker;
  final Function(PickerResponse color) onChanged;

  const ColorPicker({
    super.key,
    required this.child,
    required this.onChanged,
    this.showMarker,
    this.trackerImage,
  });

  @override
  ColorPickerState createState() => ColorPickerState();
}

class ColorPickerState extends State<ColorPicker> {
  FindPixelColor? _colorPicker;
  Offset penPosition = const Offset(0, 0); // 펜의 위치
  Color? selectedColor;
  bool isPenVisible = false; // 펜의 가시성을 제어하기 위한 변수

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  final double penTipOffsetX = 10; // 펜 촉의 x 오프셋
  final double penTipOffsetY = 50; // 펜 촉의 y 오프셋

  void _centerPen() {
    // RenderBox가 아직 렌더링되지 않았을 수 있기 때문에 WidgetsBinding 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
      _repaintBoundaryKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final Size imageSize = renderBox.size;

        setState(() {
          penPosition = Offset(
            imageSize.width / 2 - penTipOffsetX,
            imageSize.height / 2 - penTipOffsetY,
          );
          isPenVisible = true; // 펜을 보이도록 설정
          _onInteract(penPosition + Offset(penTipOffsetX, penTipOffsetY));
        });
      }
    });
  }

  Future<ui.Image> _loadSnapshot() async {
    final RenderRepaintBoundary repaintBoundary =
    _repaintBoundaryKey.currentContext!.findRenderObject()
    as RenderRepaintBoundary;

    final snapshot = await repaintBoundary.toImage();

    return snapshot;
  }

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeHandler>(context);

    return Stack(
      fit: StackFit.loose,
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 추가
            decoration: BoxDecoration(
              border: Border.all(color: themeProvider.primaryColor, width: 2.0), // 이미지에 테두리 추가
            ),
            child: widget.child,
          ),
        ),
        if (isPenVisible) // 펜이 보일 때만 화면에 출력
          Positioned(
            left: penPosition.dx,
            top: penPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final newPos = penPosition + details.delta;

                  // 펜이 이미지 밖으로 나가지 않도록 제한
                  final renderBox =
                  _repaintBoundaryKey.currentContext?.findRenderObject() as RenderBox?;
                  final Size imageSize = renderBox?.size ?? Size.zero;

                  penPosition = Offset(
                    newPos.dx.clamp(0.0, imageSize.width - penTipOffsetX),
                    newPos.dy.clamp(0.0, imageSize.height - penTipOffsetY),
                  );
                });
                _onInteract(penPosition + Offset(penTipOffsetX, penTipOffsetY));
              },
              child: const Icon(Icons.edit, size: 60, color: Colors.red),
            ),
          ),
        if (widget.showMarker ?? false) ...[
          Positioned(
            left: penPosition.dx,
            top: penPosition.dy - 50,
            child: widget.trackerImage == null
                ? Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: selectedColor ?? Colors.transparent,
                  width: 10,
                ),
              ),
              child: const Text("+"),
            )
                : widget.trackerImage!,
          )
        ]
      ],
    );
  }

  void showPen() {
    _centerPen(); // 펜을 이미지의 중앙으로 위치시키고 보이도록 설정
  }

  _onInteract(Offset offset) async {
    if (_colorPicker == null) {
      final snapshot = await _loadSnapshot();

      final imageByteData =
      await snapshot.toByteData(format: ui.ImageByteFormat.png);

      final imageBuffer = imageByteData!.buffer;

      final uint8List = imageBuffer.asUint8List();

      _colorPicker = FindPixelColor(bytes: uint8List);

      snapshot.dispose();
    }

    final color = await _colorPicker!.getColor(pixelPosition: offset);
    selectedColor = color;

    PickerResponse response = PickerResponse(
      selectedColor ?? Colors.black,
      selectedColor?.red ?? 0,
      selectedColor?.blue ?? 0,
      selectedColor?.green ?? 0,
      selectedColor?.toHex() ?? '#000000',
      penPosition.dx,
      penPosition.dy,
    );

    widget.onChanged(response);
  }
}

extension HexColor on Color {
  String toHex({bool leadingHashSign = true}) {
    return '${leadingHashSign ? '#' : ''}'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }
}