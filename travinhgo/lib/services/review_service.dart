import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/review/reply.dart';
import '../Models/review/review.dart';
import '../Models/review/review_list_response.dart';
import '../utils/env_config.dart';
import 'auth_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() {
    return _instance;
  }

  ReviewService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Review/';

  final Dio dio = Dio();

  Future<ReviewResponse?> sendReview(ReviewRequest reviewRequest) async {
    try {
      debugPrint('number of image: ${reviewRequest.images?.length ?? 0}');

      final formData = await reviewRequest.toFormData();
      debugPrint('Số lượng image trong formData: ${formData.files.length}');

      var endPoint = '${_baseUrl}AddReview';
      var sessionId = await AuthService().getSessionId();
      final response = await dio.post(
        endPoint,
        data: formData,
        options: Options(
          headers: {'sessionId': sessionId},
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('error: ' + response.toString());
        return null;
      }
      dynamic data = response.data['data'];
      ReviewResponse reviewResponse = ReviewResponse.fromJson(data);
      return reviewResponse;
    } catch (e) {
      debugPrint('Error during sending review: $e');
      return null;
    }
  }

  Future<Reply?> sendReply(ReplyRequest replyRequest) async {
    try {
      debugPrint(
          'number of image in service: ${replyRequest.images?.length ?? 0}');
      var endPoint = '${_baseUrl}AddReply';

      var sessionId = await AuthService().getSessionId();
      final response = await dio.post(
        endPoint,
        data: await replyRequest.toFormData(),
        options: Options(
          headers: {'sessionId': sessionId},
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('error: ' + response.toString());
        return null;
      }
      dynamic data = response.data['data'];
      Reply replyResponse = Reply.fromJson(data);
      return replyResponse;
    } catch (e) {
      debugPrint('Error during sending reply review: $e');
      return null;
    }
  }

  Future<ReviewListResponse?> getReviewsByDestinationId(
      String destinationId) async {
    try {
      var sessionId = await AuthService().getSessionId();
      var endPoint = '${_baseUrl}FilterReviewsMobileAsync';
      final response = await dio.get(endPoint,
          queryParameters: {'destinationId': destinationId},
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
            'sessionId': sessionId
          }));
      
      if(response.statusCode == 200) {
        final data = response.data['data'];
        return ReviewListResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return null;
    }
  }
}
