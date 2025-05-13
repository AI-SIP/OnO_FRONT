import 'package:flutter/animation.dart';

class PickerResponse {
  final Color selectionColor;
  final int redScale;
  final int blueScale;
  final int greenScale;
  final String hexCode;
  final double xpostion;
  final double ypostion;

  PickerResponse(this.selectionColor, this.redScale, this.blueScale,
      this.greenScale, this.hexCode, this.xpostion, this.ypostion);
}
