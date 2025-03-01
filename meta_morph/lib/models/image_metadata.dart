class ImageMetadata {
  final String? make;
  final String? model;
  final String? dateTime;
  final int? width;
  final int? height;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? software;
  final String? exposureTime;
  final String? fNumber;
  final int? iso;
  final String? focalLength;
  final Map<String, dynamic>? additionalData; // For any extra metadata

  ImageMetadata({
    this.make,
    this.model,
    this.dateTime,
    this.width,
    this.height,
    this.gpsLatitude,
    this.gpsLongitude,
    this.software,
    this.exposureTime,
    this.fNumber,
    this.iso,
    this.focalLength,
    this.additionalData,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    // Create a copy of json for additional data
    final additionalFields = Map<String, dynamic>.from(json);
    // Remove known fields
    [
      'make',
      'model',
      'datetime',
      'width',
      'height',
      'gps_latitude',
      'gps_longitude',
      'software',
      'exposure_time',
      'f_number',
      'iso',
      'focal_length',
    ].forEach(additionalFields.remove);

    return ImageMetadata(
      make: json['make'] as String?,
      model: json['model'] as String?,
      dateTime: json['datetime'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      gpsLatitude:
          json['gps_latitude'] != null
              ? double.tryParse(json['gps_latitude'].toString())
              : null,
      gpsLongitude:
          json['gps_longitude'] != null
              ? double.tryParse(json['gps_longitude'].toString())
              : null,
      software: json['software'] as String?,
      exposureTime: json['exposure_time'] as String?,
      fNumber: json['f_number'] as String?,
      iso: json['iso'] as int?,
      focalLength: json['focal_length'] as String?,
      additionalData: additionalFields.isNotEmpty ? additionalFields : null,
    );
  }
}
