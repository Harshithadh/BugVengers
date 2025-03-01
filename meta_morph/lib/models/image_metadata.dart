class ImageMetadata {
  final String? filename;
  final String? format;
  final String? mode;
  final Map<String, dynamic>? size;
  final Map<String, dynamic>? exif;
  final String? colorProfile;
  final Map<String, dynamic>? colorStats;
  final List<int>? histogram;

  ImageMetadata({
    this.filename,
    this.format,
    this.mode,
    this.size,
    this.exif,
    this.colorProfile,
    this.colorStats,
    this.histogram,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      filename: json['filename'] as String?,
      format: json['format'] as String?,
      mode: json['mode'] as String?,
      size: json['size'] as Map<String, dynamic>?,
      exif: json['exif'] as Map<String, dynamic>?,
      colorProfile: json['color_profile'] as String?,
      colorStats: json['color_stats'] as Map<String, dynamic>?,
      histogram: (json['histogram'] as List<dynamic>?)?.cast<int>(),
    );
  }

  // Helper getters for commonly used values
  String? get make => exif?['device']?['Make'] as String?;
  String? get model => exif?['device']?['Model'] as String?;
  String? get software => exif?['device']?['Software'] as String?;
  String? get dateTime => exif?['photo']?['DateTimeOriginal'] as String?;
  int? get width => size?['width'] as int?;
  int? get height => size?['height'] as int?;
  double? get gpsLatitude => exif?['gps']?['latitude'] as double?;
  double? get gpsLongitude => exif?['gps']?['longitude'] as double?;
  String? get exposureTime => exif?['photo']?['ExposureTime']?.toString();
  String? get fNumber => exif?['photo']?['FNumber']?.toString();
  int? get iso => exif?['photo']?['ISOSpeedRatings'] as int?;
  String? get focalLength => exif?['photo']?['FocalLength']?.toString();

  Map<String, dynamic>? get additionalExifData => exif?['other'];
}
