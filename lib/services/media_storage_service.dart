import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies picked photos into app storage so paths stay valid after restarts.
class MediaStorageService {
  MediaStorageService._();
  static final MediaStorageService instance = MediaStorageService._();

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);

  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 88);

  Future<String?> persistImage(XFile file) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}${Platform.pathSeparator}photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final dot = file.path.lastIndexOf('.');
      final ext = dot == -1 ? '.jpg' : file.path.substring(dot);
      final destPath =
          '${photosDir.path}${Platform.pathSeparator}photo_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(file.path).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}
