// ignore_for_file: avoid_print
/// Creates a 256x256 Linux icon from the generated app_icon.png.
/// Run: dart run tool/linux_icon.dart
library;

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodePng(File('assets/app_icon.png').readAsBytesSync())!;
  final resized = img.copyResize(src, width: 256, height: 256);
  File('linux/runner/app_icon.png').writeAsBytesSync(img.encodePng(resized));
  print('✓ Generated linux/runner/app_icon.png (256x256)');
}
