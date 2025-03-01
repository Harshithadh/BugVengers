import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_files_provider.dart';
import '../widgets/media_display.dart';
import '../widgets/metadata_display.dart';
import 'package:meta_morph/services/image_service.dart';
import 'dart:io';
import '../models/shared_file_model.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

class HomeScreen extends ConsumerWidget {
  final ImageService imageService = ImageService();

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedFiles = ref.watch(sharedFilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Media Viewer')),
      body:
          sharedFiles.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No media shared yet'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final File? pickedImage =
                              await imageService.pickImage();
                          if (pickedImage != null) {
                            final metadata = await imageService
                                .getImageMetadata(pickedImage);
                            ref
                                .read(sharedFilesProvider.notifier)
                                .addFile(
                                  SharedFileModel(
                                    file: SharedFile(
                                      value: pickedImage.path,
                                      type: SharedMediaType.IMAGE,
                                    ),
                                    metadata: metadata,
                                  ),
                                );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error processing image: $e'),
                            ),
                          );
                        }
                      },
                      child: const Text('Select Image'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sharedFiles.length,
                itemBuilder: (context, index) {
                  final sharedFile = sharedFiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaDisplay(sharedFile: sharedFile.file),
                        MetadataDisplay(metadata: sharedFile.metadata),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
