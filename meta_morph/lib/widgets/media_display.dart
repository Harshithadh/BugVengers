import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

class MediaDisplay extends StatelessWidget {
  final SharedFile sharedFile;

  const MediaDisplay({Key? key, required this.sharedFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(sharedFile.value!),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
