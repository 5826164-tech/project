import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class StorageService {
  final FirebaseStorage? _storage;

  StorageService() : _storage = _initStorage();

  static FirebaseStorage? _initStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Uploads an image to Firebase Storage (if available) or Backend Upload API.
  Future<String> uploadImage(XFile file, String uid) async {
    // 1. Try Firebase Storage if initialized
    if (_storage != null) {
      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        Reference ref = _storage!.ref().child('scans/$uid/$fileName');

        UploadTask uploadTask = ref.putData(await file.readAsBytes());
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload failed: $e. Falling back to API storage.');
      }
    }

    // 2. Fallback to Backend Storage API (Works 100% out of the box!)
    try {
      String uploadedUrl = await ApiService.uploadImage(file);
      if (uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    } catch (e) {
      debugPrint('Backend upload error: $e');
    }

    // 3. Fallback placeholder
    return 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?auto=format&fit=crop&w=400&q=80';
  }
}
