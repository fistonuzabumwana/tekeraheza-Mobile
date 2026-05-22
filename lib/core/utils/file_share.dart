import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SharedFile {
  const SharedFile({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });

  final String filename;
  final Uint8List bytes;
  final String? mimeType;
}

class FileShare {
  static Future<void> shareBytes(
    SharedFile file, {
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${file.filename}';
    final f = File(path);
    await f.writeAsBytes(file.bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: file.mimeType, name: file.filename)],
        text: text,
      ),
    );
  }
}

