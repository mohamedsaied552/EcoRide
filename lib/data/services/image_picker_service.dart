import 'package:image_picker/image_picker.dart';

import 'package:glider/domain/entities/picked_image_data.dart';

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<PickedImageData?> pickIdImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 55,
        maxWidth: 960,
        maxHeight: 960,
      );

      if (file == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      return PickedImageData(
        bytes: bytes,
        fileName: file.name,
      );
    } on Exception catch (error) {
      throw Exception(_mapImageError(error));
    }
  }

  String _mapImageError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission')) {
      return 'Permission denied while trying to access your camera or gallery.';
    }
    if (message.contains('camera_access_denied')) {
      return 'Camera access was denied. Please enable it and try again.';
    }
    return 'Unable to pick an image right now. Please try again.';
  }
}
