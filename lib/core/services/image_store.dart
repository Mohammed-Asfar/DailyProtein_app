import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns product photos on disk.
///
/// Picked images are copied into the app's own documents directory rather
/// than referenced where they sit: a gallery file can be deleted or moved
/// by the user, and the product would then show a broken image.
class ImageStore {
  ImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const String _folder = 'product_images';

  Future<Directory> _directory() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _folder));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Opens the camera or gallery and copies the result into app storage.
  /// Returns the stored path, or null if the user backed out.
  Future<String?> pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      // Product thumbnails are small; full-resolution photos would bloat
      // storage and backups for no visible gain.
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final Directory dir = await _directory();
    final String name =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final String target = p.join(dir.path, name);
    await File(picked.path).copy(target);
    return target;
  }

  /// Removes a stored photo, ignoring one that has already gone.
  Future<void> delete(String? path) async {
    if (path == null) return;
    final File file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Whether a stored path still resolves to a file on disk.
  bool exists(String? path) => path != null && File(path).existsSync();
}
