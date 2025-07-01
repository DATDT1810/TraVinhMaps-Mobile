import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/Models/feedback/feedback_request.dart';

import '../utils/env_config.dart';
import 'auth_service.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();

  factory FeedbackService() {
    return _instance;
  }

  FeedbackService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Feedback/';

  final Dio dio = Dio();

  Future<bool> sendFeedback(FeedbackRequest feedbackRequest) async {
    try {
      var endPoint = '${_baseUrl}send';
      var sessionId =  await AuthService().getSessionId();
      debugPrint('token:: '+ sessionId!);
      final response = await dio.post(
        endPoint,
        data: await feedbackRequest.toFormData(),
        options: Options(
          headers: {
            'sessionId': sessionId
          },
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('error: '+ response.toString());
        return false;
      }
      debugPrint('Success:: '+ response.toString());
      return true;
    } catch (e) {
      debugPrint('Error during sending feedback: $e');
      return false;
    }
  }
}
