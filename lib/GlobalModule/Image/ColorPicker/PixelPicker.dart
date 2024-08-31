import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'FindPixelColor.dart';
import 'PickerResponse.dart';

class ColorPicker extends StatefulWidget {
  final Widget child;
  final Widget? trackerImage;
  final bool? showMarker;
  final Function(PickerResponse color) onChanged;

  const ColorPicker({
    Key? key,
    required this.child,
    required this.onChanged,
    this.showMarker,
    this.trackerImage,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  FindPixelColor? _colorPicker;
  Offset fingerPosition = Offset(0, 0);
  Color? selectedColor;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  Future<ui.Image> _loadSnapshot() async {
    final RenderRepaintBoundary repaintBoundary =
    _repaintBoundaryKey.currentContext!.findRenderObject()
    as RenderRepaintBoundary;

    final snapshot = await repaintBoundary.toImage();

    return snapshot;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.loose,
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: GestureDetector(
            onTapDown: (details) {
              final offset = details.localPosition;
              fingerPosition = offset;
              _onInteract(offset);
            },
            child: widget.child,
          ),
        ),
        if (widget.showMarker ?? false) ...[
          Positioned(
            left: fingerPosition.dx,
            top: fingerPosition.dy - 50,
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
      fingerPosition.dx,
      fingerPosition.dy,
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