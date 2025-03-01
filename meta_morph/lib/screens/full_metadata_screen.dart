import 'package:flutter/material.dart';
import '../models/image_metadata_model.dart';

class FullMetadataScreen extends StatelessWidget {
  final ImageMetadata metadata;

  const FullMetadataScreen({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    // return Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('All Metadata'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetadataSection(
            title: 'Device Information',
            icon: Icons.phone_android,
            data: metadata.deviceInfo,
          ),
          _buildMetadataSection(
            title: 'Photo Information',
            icon: Icons.camera_alt,
            data: metadata.photoInfo,
          ),
          _buildMetadataSection(
            title: 'Technical Details',
            icon: Icons.settings,
            data: metadata.allMetadata,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection({
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...data.entries.map(
              (entry) => _buildNestedData(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNestedData(String key, dynamic value, [int depth = 0]) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0, top: 8, bottom: 4),
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ...value.entries.map(
            (entry) => _buildNestedData(entry.key, entry.value, depth + 1),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
