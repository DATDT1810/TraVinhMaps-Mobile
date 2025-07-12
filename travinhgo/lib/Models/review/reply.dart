import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class Reply {
  final String? content;
  final List<String>? images;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String avatar;

  Reply({
    this.content,
    this.images,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.avatar,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      content: json['content'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      userName: json['userName'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}


class ReplyRequest {
  final String id;
  final String content;
  final List<File>? images;
  ReplyRequest({required this.id, required this.content, this.images});

  Future<FormData> toFormData() async {

    debugPrint('[ReplyRequest.toFormData] images = ${images}');
    debugPrint('[ReplyRequest.toFormData] images.length = ${images?.length}');
    debugPrint('[ReplyRequest.toFormData] image paths = ${images?.map((e) => e.path).toList()}');

    final formData = FormData();

    formData.fields.add(MapEntry('Id', id));
    formData.fields.add(MapEntry('Content', content));

    if (images != null && images!.isNotEmpty) {
      final localImages = List<File>.from(images!);
      for (var image in localImages) {
        if (await image.exists()) {
          final fileName = image.path.split('/').last;
          formData.files.add(
            MapEntry(
              'Images',
              await MultipartFile.fromFile(image.path, filename: fileName),
            ),
          );
        } else {
          debugPrint('Image file not found: ${image.path}');
        }
      }
    } else {
      debugPrint('No images provided for reply.');
    }
    
    return formData;
  }
}