import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import '../models/image_metadata_model.dart';
import '../services/metadata_service.dart';
import '../screens/modification_success_screen.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker_mb.dart';

class EditMetadataScreen extends StatefulWidget {
  final ImageMetadata metadata;
  final String imagePath;

  const EditMetadataScreen({
    super.key,
    required this.metadata,
    required this.imagePath,
  });

  @override
  State<EditMetadataScreen> createState() => _EditMetadataScreenState();
}

class _EditMetadataScreenState extends State<EditMetadataScreen> {
  final _metadataService = MetadataService();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _softwareController;
  DateTime? _selectedDateTime;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(
      text: widget.metadata.deviceInfo['Make'],
    );
    _modelController = TextEditingController(
      text: widget.metadata.deviceInfo['Model'],
    );
    _softwareController = TextEditingController(
      text: widget.metadata.deviceInfo['Software'],
    );

    if (widget.metadata.dateTime != null) {
      final formattedDate = widget.metadata.dateTime!
          .replaceFirst(':', '-')
          .replaceFirst(':', '-');
      _selectedDateTime = DateTime.parse(formattedDate);
    } else {
      _selectedDateTime = DateTime.now();
    }

    if (widget.metadata.latitude != null && widget.metadata.longitude != null) {
      _selectedLocation = LatLng(
        widget.metadata.latitude!,
        widget.metadata.longitude!,
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    final updatedMetadata = {
      'filename': widget.metadata.allMetadata['filename'],
      'format': widget.metadata.allMetadata['format'],
      'mode': widget.metadata.allMetadata['mode'],
      'size': widget.metadata.allMetadata['size'],
      'exif': {
        'device': {
          'Make': _makeController.text,
          'Model': _modelController.text,
          'Software': _softwareController.text,
        },
        'image': widget.metadata.allMetadata['exif']['image'],
        'photo': {
          ...widget.metadata.allMetadata['exif']['photo'],
          'DateTimeOriginal':
              _selectedDateTime
                  ?.toIso8601String()
                  .replaceAll('-', ':')
                  .replaceAll('T', ' ')
                  .split('.')[0],
        },
        'gps':
            _selectedLocation != null
                ? {
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                  'altitude':
                      widget.metadata.allMetadata['exif']['gps']['altitude'],
                  'timestamp':
                      widget.metadata.allMetadata['exif']['gps']['timestamp'],
                  'raw': widget.metadata.allMetadata['exif']['gps']['raw'],
                }
                : widget.metadata.allMetadata['exif']['gps'],
        'other': {
          ...widget.metadata.allMetadata['exif']['other'],
          'DateTime':
              _selectedDateTime
                  ?.toIso8601String()
                  .replaceAll('-', ':')
                  .replaceAll('T', ' ')
                  .split('.')[0],
          'DateTimeDigitized':
              _selectedDateTime
                  ?.toIso8601String()
                  .replaceAll('-', ':')
                  .replaceAll('T', ' ')
                  .split('.')[0],
        },
      },
      'color_profile': widget.metadata.allMetadata['color_profile'],
      'color_stats': widget.metadata.allMetadata['color_stats'],
      'histogram': widget.metadata.allMetadata['histogram'],
    };

    final modifiedImageBytes = await _metadataService.modifyMetadata(
      widget.imagePath,
      {'metadata': updatedMetadata},
    );
    print(modifiedImageBytes);
    setState(() => _isLoading = false);

    if (modifiedImageBytes != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ModificationSuccessScreen(imageBytes: modifiedImageBytes),
        ),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update metadata')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Metadata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDeviceSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildDeviceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _makeController,
              decoration: const InputDecoration(labelText: 'Make'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _softwareController,
              decoration: const InputDecoration(labelText: 'Software'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedLocation != null)
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                    ),
                  },
                  onTap: (LatLng position) {
                    setState(() => _selectedLocation = position);
                  },
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final selectedPlace = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlacePicker(
                          apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                          onPlacePicked: (result) {
                            Navigator.of(context).pop(result);
                          },
                          initialPosition:
                              _selectedLocation ?? const LatLng(0.0, 0.0),
                          useCurrentLocation: true,
                        ),
                  ),
                );

                if (selectedPlace != null) {
                  setState(() {
                    _selectedLocation = LatLng(
                      selectedPlace.geometry!.location.lat,
                      selectedPlace.geometry!.location.lng,
                    );
                  });
                }
              },
              icon: const Icon(Icons.edit_location),
              label: const Text('Select Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDateTime?.toString() ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      _selectedDateTime ?? DateTime.now(),
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
