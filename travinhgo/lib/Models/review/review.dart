import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/Models/review/reply.dart';

class ReviewResponse {
  final String id;
  final int rating;
  final List<String>? images;
  final String? comment;
  final String userId;
  final String userName;
  final String avatar;
  final String destinationId;
  final DateTime createdAt;
  final List<Reply> reply;

  ReviewResponse({
    required this.id,
    required this.rating,
    this.images,
    this.comment,
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.destinationId,
    required this.createdAt,
    List<Reply>? reply,
  }) : reply = reply ?? [];

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'],
      rating: json['rating'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      comment: json['comment'],
      userId: json['userId'],
      userName: json['userName'] ?? '',
      avatar: json['avatar'] ?? '',
      destinationId: json['destinationId'],
      createdAt: DateTime.parse(json['createdAt']),
      reply: json['reply'] != null
          ? List<Reply>.from(json['reply'].map((e) => Reply.fromJson(e)))
          : [],
    );
  }
}

class ReviewRequest {
  final int rating;
  final List<File>? images;
  final String comment;
  final String destinationId;

  ReviewRequest(
      {required this.rating,
      this.images,
      required this.comment,
      required this.destinationId});

  Future<FormData> toFormData() async {
    final formData = FormData();

    formData.fields.add(MapEntry('Rating', rating.toString()));
    formData.fields.add(MapEntry('Comment', comment));
    formData.fields.add(MapEntry('DestinationId', destinationId));

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

    return formData;
  }
}
