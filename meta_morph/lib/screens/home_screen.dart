import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/shared_files_provider.dart';
import '../models/image_metadata_model.dart';
import '../models/shared_file_model.dart';
import 'image_details_screen.dart';
import 'dart:io';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedFiles = ref.watch(sharedFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Media Viewer'),
        centerTitle: true,
      ),
      body:
          sharedFiles.isEmpty
              ? Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final result = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (result != null) {
                        final file = File(result.path);

                        // Show loading indicator
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Processing image...'),
                            ),
                          );
                        }

                        final metadata = await ref
                            .read(imageServiceProvider)
                            .getImageMetadata(file);

                        if (metadata != null && context.mounted) {
                          // Add to shared files list first
                          ref
                              .read(sharedFilesProvider.notifier)
                              .addFile(
                                SharedFileModel(
                                  file: SharedFile(
                                    value: file.path,
                                    type: SharedMediaType.IMAGE,
                                  ),
                                  metadata: metadata,
                                  filename: file.path.split('/').last,
                                  mimeType: 'image/jpeg',
                                ),
                              );

                          // Then navigate
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ImageDetailsScreen(
                                    metadata: ImageMetadata.fromJson(metadata),
                                  ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error processing image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      print('Error: $e'); // For debugging
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload Image'),
                ),
              )
              : ListView.builder(
                itemCount: sharedFiles.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final file = sharedFiles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        try {
                          if (file.metadata != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ImageDetailsScreen(
                                      metadata: ImageMetadata.fromJson(
                                        file.metadata!,
                                      ),
                                    ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error viewing details: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (file.file.value != null)
                            Image.file(
                              File(file.file.value!),
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Icon(Icons.error_outline),
                                  ),
                                );
                              },
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.filename ?? 'Unknown file',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                if (file.metadata != null &&
                                    file.metadata!['exif'] != null &&
                                    file.metadata!['exif']['device'] !=
                                        null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Device: ${file.metadata!['exif']['device']['Make'] ?? ''} ${file.metadata!['exif']['device']['Model'] ?? ''}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
