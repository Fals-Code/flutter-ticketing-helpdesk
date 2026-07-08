import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const String sourcePath = 'assets/icons/app_icon.png';

const String legacyOut = 'assets/icons/app_icon_legacy.png';
const String iosOut = 'assets/icons/app_icon_ios.png';
const String adaptiveFgOut = 'assets/icons/app_icon_adaptive_foreground.png';
const String adaptiveBgOut = 'assets/icons/app_icon_adaptive_background.png';

const int bgR = 10;
const int bgG = 36;
const int bgB = 99;

void main() {
  final file = File(sourcePath);
  if (!file.existsSync()) {
    throw StateError('Source icon not found: $sourcePath');
  }

  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    throw StateError('Failed to decode: $sourcePath');
  }

  final cropped = _trimOuterUniformBackground(decoded);

  _buildSquareIcon(
    source: cropped,
    outputPath: legacyOut,
    size: 1024,
    contentScale: 0.68,
    transparentBackground: false,
  );

  _buildSquareIcon(
    source: cropped,
    outputPath: iosOut,
    size: 1024,
    contentScale: 0.68,
    transparentBackground: false,
  );

  _buildSquareIcon(
    source: cropped,
    outputPath: adaptiveFgOut,
    size: 432,
    contentScale: 0.52,
    transparentBackground: true,
  );

  final adaptiveBg = img.Image(width: 432, height: 432, numChannels: 4);
  img.fill(adaptiveBg, color: img.ColorRgba8(bgR, bgG, bgB, 255));

  File(adaptiveBgOut)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(adaptiveBg));

  stdout.writeln('Generated:');
  stdout.writeln('- $legacyOut');
  stdout.writeln('- $iosOut');
  stdout.writeln('- $adaptiveFgOut');
  stdout.writeln('- $adaptiveBgOut');
}

img.Image _trimOuterUniformBackground(img.Image source) {
  final bg = source.getPixel(0, 0);
  final bgR0 = bg.r.toInt();
  final bgG0 = bg.g.toInt();
  final bgB0 = bg.b.toInt();

  const tolerance = 20;
  const alphaThreshold = 10;

  bool isBackgroundLike(img.Pixel p) {
    final a = p.a.toInt();
    final r = p.r.toInt();
    final g = p.g.toInt();
    final b = p.b.toInt();

    if (a <= alphaThreshold) return true;

    return (r - bgR0).abs() <= tolerance &&
        (g - bgG0).abs() <= tolerance &&
        (b - bgB0).abs() <= tolerance;
  }

  int minX = source.width;
  int minY = source.height;
  int maxX = -1;
  int maxY = -1;

  for (int y = 0; y < source.height; y++) {
    for (int x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      if (!isBackgroundLike(p)) {
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    throw StateError('Visible content not found in source icon.');
  }

  final width = maxX - minX + 1;
  final height = maxY - minY + 1;
  final pad = (math.max(width, height) * 0.06).round();

  final cropX = math.max(0, minX - pad);
  final cropY = math.max(0, minY - pad);
  final cropRight = math.min(source.width - 1, maxX + pad);
  final cropBottom = math.min(source.height - 1, maxY + pad);

  return img.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropRight - cropX + 1,
    height: cropBottom - cropY + 1,
  );
}

void _buildSquareIcon({
  required img.Image source,
  required String outputPath,
  required int size,
  required double contentScale,
  required bool transparentBackground,
}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);

  img.fill(
    canvas,
    color: transparentBackground
        ? img.ColorRgba8(0, 0, 0, 0)
        : img.ColorRgba8(bgR, bgG, bgB, 255),
  );

  final longestSide = math.max(source.width, source.height);
  final targetLongest = (size * contentScale).round();

  final targetWidth = (source.width * targetLongest / longestSide).round();
  final targetHeight = (source.height * targetLongest / longestSide).round();

  final resized = img.copyResize(
    source,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.cubic,
  );

  img.compositeImage(
    canvas,
    resized,
    dstX: ((size - targetWidth) / 2).round(),
    dstY: ((size - targetHeight) / 2).round(),
  );

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(canvas));
}
