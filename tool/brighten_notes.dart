import 'dart:io';
import 'package:image/image.dart' as img;

/// 공책 그림을 조금 밝게 한다.
///
/// 밝은 쪽을 더 들어 올리고 어두운 윤곽선은 덜 건드린다. 점토의 입체감을
/// 만드는 것이 그 윤곽선이라, 통째로 밝히면 그림이 흐물거린다.
void main(List<String> args) {
  final k = double.parse(args.first);
  for (final name in args.skip(1)) {
    final path = 'assets/Icon/$name.png';
    final src = img.decodePng(File(path).readAsBytesSync())!;
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final c = src.getPixel(x, y);
        final a = img.getAlpha(c);
        if (a == 0) continue;
        int lift(int v) {
          final t = v / 255.0;
          return ((t + (1 - t) * k * t) * 255).round().clamp(0, 255);
        }
        src.setPixel(x, y, img.getColor(
          lift(img.getRed(c)), lift(img.getGreen(c)), lift(img.getBlue(c)), a));
      }
    }
    File(path).writeAsBytesSync(img.encodePng(src, level: 6));
    stdout.writeln('  $name');
  }
}
