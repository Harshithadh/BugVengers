import 'package:flutter/material.dart';
import '../models/image_metadata.dart';

class MetadataDisplay extends StatelessWidget {
  final ImageMetadata? metadata;

  const MetadataDisplay({Key? key, required this.metadata}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (metadata == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No metadata available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Camera Information', [
            _buildMetadataRow(
              '📸 Camera',
              '${metadata!.make} ${metadata!.model}',
            ),
            if (metadata!.software != null)
              _buildMetadataRow('📱 Software', metadata!.software!),
          ]),
          _buildSection('Image Details', [
            _buildMetadataRow('📅 Date', metadata!.dateTime ?? 'Unknown'),
            _buildMetadataRow(
              '📏 Resolution',
              '${metadata!.width}x${metadata!.height}',
            ),
          ]),
          if (_hasExposureData)
            _buildSection('Camera Settings', [
              if (metadata!.exposureTime != null)
                _buildMetadataRow('⚡ Exposure', metadata!.exposureTime!),
              if (metadata!.fNumber != null)
                _buildMetadataRow('🎯 F-Number', metadata!.fNumber!),
              if (metadata!.iso != null)
                _buildMetadataRow('📊 ISO', metadata!.iso.toString()),
              if (metadata!.focalLength != null)
                _buildMetadataRow('🔍 Focal Length', metadata!.focalLength!),
            ]),
          if (_hasLocation)
            _buildSection('Location', [
              _buildMetadataRow(
                '📍 Coordinates',
                '${metadata!.gpsLatitude}, ${metadata!.gpsLongitude}',
              ),
            ]),
          if (metadata!.additionalData != null)
            _buildSection(
              'Additional Information',
              metadata!.additionalData!.entries
                  .map((e) => _buildMetadataRow(e.key, e.value.toString()))
                  .toList(),
            ),
        ],
      ),
    );
  }

  bool get _hasExposureData =>
      metadata!.exposureTime != null ||
      metadata!.fNumber != null ||
      metadata!.iso != null ||
      metadata!.focalLength != null;

  bool get _hasLocation =>
      metadata!.gpsLatitude != null && metadata!.gpsLongitude != null;

  Widget _buildSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
