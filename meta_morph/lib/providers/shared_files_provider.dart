import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import '../models/shared_file_model.dart';
import '../services/image_service.dart';

final imageServiceProvider = Provider((ref) => ImageService());

final sharedFilesProvider =
    StateNotifierProvider<SharedFilesNotifier, List<SharedFileModel>>((ref) {
      return SharedFilesNotifier(ref);
    });

class SharedFilesNotifier extends StateNotifier<List<SharedFileModel>> {
  final Ref ref;
  late StreamSubscription _intentDataStreamSubscription;

  SharedFilesNotifier(this.ref) : super([]) {
    _initSharing();
  }

  Future<void> _initSharing() async {
    try {
      // Get initial shared files first
      final initialFiles =
          await FlutterSharingIntent.instance.getInitialSharing();
      if (initialFiles.isNotEmpty) {
        await _handleSharedFiles(initialFiles);
      }

      // Then listen for new shares
      _intentDataStreamSubscription = FlutterSharingIntent.instance
          .getMediaStream()
          .listen(
            (List<SharedFile> files) async {
              print("Received shared files: ${files.length}");
              await _handleSharedFiles(files);
            },
            onError: (error) {
              print("Error in sharing stream: $error");
            },
          );
    } catch (e) {
      print("Error initializing sharing: $e");
    }
  }

  Future<void> _handleSharedFiles(List<SharedFile> files) async {
    try {
      // First update state with basic file info
      final models = files.map((file) => SharedFileModel(file: file)).toList();
      state = models;

      // Then fetch metadata for images
      for (var i = 0; i < models.length; i++) {
        if (models[i].file.type == SharedMediaType.IMAGE) {
          try {
            final metadata = await ref
                .read(imageServiceProvider)
                .getImageMetadata(File(models[i].file.value!));

            state = [
              ...state.sublist(0, i),
              SharedFileModel(file: models[i].file, metadata: metadata),
              ...state.sublist(i + 1),
            ];
          } catch (e) {
            print('Error fetching metadata for image $i: $e');
          }
        }
      }
    } catch (e) {
      print('Error handling shared files: $e');
    }
  }

  void addFile(SharedFileModel file) {
    state = [...state, file];
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}
