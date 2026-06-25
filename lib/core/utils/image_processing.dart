import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessing {
  static Uint8List process(Uint8List bytes, {int maxWidth = 1920, int quality = 80}) {
    var image = img.decodeImage(bytes);
    if (image == null) return bytes;
    image = img.bakeOrientation(image);
    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}
