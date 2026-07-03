import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PickedAttachment {
  const PickedAttachment({required this.path, this.mimeType});

  final String path;
  final String? mimeType;
}

/// Picks an image and persists it into app storage. Abstracted so widget
/// tests can fake the camera/gallery.
abstract interface class AttachmentPicker {
  Future<PickedAttachment?> pickImage({required bool fromCamera});
}

class ImagePickerAttachmentPicker implements AttachmentPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedAttachment?> pickImage({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85, // compressed at pick time — invoices stay legible
    );
    if (file == null) return null;

    // Web: no app-documents filesystem; the blob path is the reference.
    if (kIsWeb) return PickedAttachment(path: file.path, mimeType: file.mimeType);

    // Copy out of the picker's temp cache so the OS can't reclaim it.
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${dir.path}/attachments');
    await attachmentsDir.create(recursive: true);
    final ext = file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final stored = '${attachmentsDir.path}/${const Uuid().v4()}.$ext';
    await File(file.path).copy(stored);
    return PickedAttachment(path: stored, mimeType: file.mimeType);
  }
}

final attachmentPickerProvider = Provider<AttachmentPicker>((ref) {
  return ImagePickerAttachmentPicker();
});
