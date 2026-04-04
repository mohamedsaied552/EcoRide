import 'dart:typed_data';

class PickedImageData {
  const PickedImageData({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}
