import 'dart:io';
import 'package:dio/dio.dart';

class FeedbackRequest {
  final String content;
  final List<File>? images;

  FeedbackRequest({
    required this.content,
    this.images,
  });

  Future<FormData> toFormData() async {
    final formData = FormData();

    formData.fields.add(MapEntry('Content', content));

    if (images != null && images!.isNotEmpty) {
      for (var image in images!) {
        final fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'Images',
            await MultipartFile.fromFile(image.path, filename: fileName),
          ),
        );
      }
    }

    return formData;
  }
}
