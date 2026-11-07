import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<List<String>> uploadProductImages({
    required String uid,
    required String productId,
    required List<XFile> images,
    ValueChanged<double>? onProgress,
  }) async {
    if (images.length > 5) {
      throw ArgumentError('Choose no more than five product images.');
    }

    final preparedImages = <({Uint8List bytes, String extension})>[];
    for (final file in images) {
      final extension = _extensionFor(file.name);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
        throw ArgumentError('Each image must be less than 5 MB.');
      }
      preparedImages.add((bytes: bytes, extension: extension));
    }

    final uploadedReferences = <Reference>[];
    final urls = <String>[];
    try {
      for (var index = 0; index < preparedImages.length; index++) {
        final image = preparedImages[index];
        final reference = _storage.ref(
          'products/$uid/$productId/$index.${image.extension}',
        );
        final task = reference.putData(
          image.bytes,
          SettableMetadata(
            contentType: _contentTypeFor(image.extension),
          ),
        );
        await task;
        uploadedReferences.add(reference);
        urls.add(await reference.getDownloadURL());
        onProgress?.call(urls.length / images.length);
      }
      return urls;
    } on FirebaseException catch (error, stackTrace) {
      try {
        await _deleteReferences(uploadedReferences);
      } on FirebaseException catch (cleanupError) {
        Error.throwWithStackTrace(
          FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-cleanup-failed',
            message:
                'Image upload failed (${error.code}), and cleanup failed (${cleanupError.code}).',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String> uploadProfileImage({
    required String uid,
    required XFile image,
    ValueChanged<double>? onProgress,
  }) async {
    final extension = _extensionFor(image.name);
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw ArgumentError('The profile image must be less than 5 MB.');
    }

    final reference = _storage.ref('profileImages/$uid/profile');
    final task = reference.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFor(extension)),
    );
    await for (final snapshot in task.snapshotEvents) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    }
    await task;
    return reference.getDownloadURL();
  }

  Future<void> deleteProductImages({
    required String uid,
    required String productId,
  }) async {
    final directory = _storage.ref('products/$uid/$productId');
    final files = await directory.listAll();
    await _deleteReferences(files.items);
  }

  Future<void> _deleteReferences(List<Reference> references) async {
    for (final reference in references) {
      await reference.delete();
    }
  }

  String _extensionFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'jpeg' || extension == 'jpg') return extension;
    if (extension == 'png' || extension == 'webp') return extension;
    throw ArgumentError('Use JPEG, PNG, or WebP images.');
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError.value(extension, 'extension'),
    };
  }
}
