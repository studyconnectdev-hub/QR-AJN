import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_bootstrap.dart';

enum BusinessMediaKind { profilePhoto, logo, cover, brochure, gallery }

class MediaUploadService {
  const MediaUploadService._();

  static Future<String?> pickAndUpload({
    required BusinessMediaKind kind,
    List<String>? allowedExtensions,
  }) async {
    if (!FirebaseBootstrap.available) {
      throw StateError('Firebase is not configured.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before uploading business media.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions == null ? FileType.image : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('The selected file could not be read.');
    }

    final maximumBytes =
        kind == BusinessMediaKind.brochure ? 10 * 1024 * 1024 : 5 * 1024 * 1024;
    if (bytes.length > maximumBytes) {
      throw StateError(
        kind == BusinessMediaKind.brochure
            ? 'Brochure must be smaller than 10 MB.'
            : 'Image must be smaller than 5 MB.',
      );
    }

    final extension = (file.extension ?? 'bin').toLowerCase();
    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';
    final reference = FirebaseStorage.instance
        .ref('business_media/${user.uid}/${kind.name}/$safeName');

    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      customMetadata: <String, String>{
        'ownerUid': user.uid,
        'mediaKind': kind.name,
      },
    );
    try {
      final snapshot =
          await reference.putData(Uint8List.fromList(bytes), metadata);
      return snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StateError(
        'Cloud media uploads are not active yet. The QR AJN administrator '
        'must enable Firebase Storage before uploading photos, logos, '
        'brochures or gallery files. (${error.code})',
      );
    }
  }

  static String _contentType(String extension) => switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'svg' => 'image/svg+xml',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };
}
