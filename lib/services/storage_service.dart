import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;
  static final _picker  = ImagePicker();

  static Future<XFile?> pickImage() => _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

  static Future<String?> uploadMenuItemImage(String itemId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final ref   = _storage.ref('menuItems/$itemId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> uploadCategoryImage(
      String category, XFile file) async {
    try {
      final safe  = category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final bytes = await file.readAsBytes();
      final ref   = _storage.ref('categories/$safe.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
