import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:meta_morph/consts.dart';

class MetadataService {
  Future<Uint8List?> modifyMetadata(
    String imagePath,
    Map<String, dynamic> modifications,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/modify_metadata'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      request.fields['modifications'] = jsonEncode(modifications);
      print(request.fields);
      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        final responseData = jsonDecode(response.body);
        final base64Image = responseData['image'] as String;
        return base64Decode(base64Image);
      }
      return null;
    } catch (e) {
      print('Error modifying metadata: $e');
      return null;
    }
  }
}
