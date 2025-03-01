import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meta_morph/consts.dart';
import 'dart:convert';
import '../models/image_metadata.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static const String baseUrl = BASE_URL; // For Android emulator
  final ImagePicker _picker = ImagePicker();

  Future<ImageMetadata> getImageMetadata(File imageFile) async {
    try {
      // Verify file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/get_meta_data'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // or appropriate image type
        ),
      );
      print(request.files);
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return ImageMetadata.fromJson(json.decode(responseData));
      } else {
        throw Exception('Failed to get metadata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting metadata: $e');
    }
  }

  Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking image: $e');
    }
  }
}
