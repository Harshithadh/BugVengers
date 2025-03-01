import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'image_metadata.dart';

class SharedFileModel {
  final SharedFile file;
  ImageMetadata? metadata;

  SharedFileModel({required this.file, this.metadata});
}
