import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meta_morph/consts.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static const String baseUrl = BASE_URL;
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>> getImageMetadata(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final request = http.MultipartRequest(
        'POST',

        Uri.parse('$baseUrl/get_meta_data'),
      );

      final file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', '*'),
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        throw Exception('Failed to get metadata: ${response.statusCode}');
      }

      final jsonResponse = json.decode(response.body);
      return {
        'exif': {
          'device': jsonResponse['exif']['device'],
          'photo': jsonResponse['exif']['photo'],
          'gps': jsonResponse['exif']['gps'],
          'other': jsonResponse['exif']['other'],
        },
      };
    } catch (e) {
      print('Error getting metadata: $e');
      rethrow;
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
