import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta_morph/consts.dart';

class MetadataService {
  Future<bool> modifyMetadata(
    String imagePath,
    Map<String, dynamic> modifications,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/modify_metadata'),
      );

      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Add the JSON data
      request.fields['modifications'] = jsonEncode(modifications);

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error modifying metadata: $e');
      return false;
    }
  }
}
