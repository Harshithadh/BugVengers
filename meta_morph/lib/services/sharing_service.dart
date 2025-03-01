import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import '../models/shared_file_model.dart';

class SharingService {
  Stream<List<SharedFileModel>> getMediaStream() {
    return FlutterSharingIntent.instance.getMediaStream().map(
      (files) => files.map((file) => SharedFileModel(file: file)).toList(),
    );
  }

  Future<List<SharedFileModel>> getInitialSharing() {
    return FlutterSharingIntent.instance.getInitialSharing().then(
      (files) => files.map((file) => SharedFileModel(file: file)).toList(),
    );
  }
}
