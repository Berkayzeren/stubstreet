import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  const inputPath = 'assets/images/logo_yazisiz.png';
  const outputPath = 'assets/images/logo_monochrome.png';

  final file = File(inputPath);
  if (!await file.exists()) {
    stderr.writeln('Input image not found: $inputPath');
    exit(1);
  }
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Failed to decode input image');
    exit(1);
  }

  // Convert to single-channel and then to black with alpha mask
  final gray = img.grayscale(image);

  // Invert if needed to ensure logo is solid and background transparent
  for (int y = 0; y < gray.height; y++) {
    for (int x = 0; x < gray.width; x++) {
      final p = gray.getPixel(x, y);
      // Assume transparent background (alpha 0) stays transparent,
      // Logo strokes become opaque with white color; Android will tint.
      if (p.a > 0) {
        // Make foreground white; leave alpha as is for edges
        gray.setPixelRgba(x, y, 255, 255, 255, p.a);
      } else {
        gray.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final out = File(outputPath);
  await out.parent.create(recursive: true);
  await out.writeAsBytes(img.encodePng(gray));
  stdout.writeln('Generated monochrome icon: $outputPath');
}


