import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'dart:typed_data';

class SharedFileModel {
  final SharedFile file;
  final String? filename;
  final String? mimeType;
  final Uint8List? thumbnail;
  final Map<String, dynamic>? metadata;

  SharedFileModel({
    required this.file,
    this.filename,
    this.mimeType,
    this.thumbnail,
    this.metadata,
  });
}
