import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // Paths
  const String inputLogoPath = 'assets/images/logo_yazisiz.png';
  const String outputIconPath = 'assets/images/logo_ios_purple.png';

  // Brand color (Deep Purple #673AB7)
  const int r = 0x67;
  const int g = 0x3A;
  const int b = 0xB7;

  // Load logo
  final inputFile = File(inputLogoPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input logo not found at: $inputLogoPath');
    exit(1);
  }
  final logoBytes = await inputFile.readAsBytes();
  final logo = img.decodeImage(logoBytes);
  if (logo == null) {
    stderr.writeln('Failed to decode input logo image.');
    exit(1);
  }

  // Create background 1024x1024
  final int size = 1024;
  final bg = img.Image(width: size, height: size);
  img.fill(bg, color: img.ColorRgb8(r, g, b));

  // Scale logo to 70% of canvas width (keeping aspect ratio)
  final double targetWidth = size * 0.7;
  final scale = targetWidth / logo.width;
  final int scaledWidth = (logo.width * scale).round();
  final int scaledHeight = (logo.height * scale).round();
  final scaledLogo = img.copyResize(logo, width: scaledWidth, height: scaledHeight, interpolation: img.Interpolation.cubic);

  // Composite centered
  final int offsetX = ((size - scaledWidth) / 2).round();
  final int offsetY = ((size - scaledHeight) / 2).round();
  img.compositeImage(bg, scaledLogo, dstX: offsetX, dstY: offsetY);

  // Ensure output directory exists
  final outFile = File(outputIconPath);
  await outFile.parent.create(recursive: true);

  // Save PNG
  final encoded = img.encodePng(bg);
  await outFile.writeAsBytes(encoded);

  stdout.writeln('Generated iOS icon: $outputIconPath');
}


