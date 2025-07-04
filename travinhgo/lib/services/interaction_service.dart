import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'auth_service.dart';

import '../Models/interaction/interaction.dart';
import '../utils/env_config.dart';

class InteractionService {
  static final InteractionService _instance = InteractionService._internal();

  factory InteractionService() {
    return _instance;
  }

  InteractionService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/Interaction/';

  final Dio dio = Dio();

  Future<bool> sendInteraction(
      List<InteractionRequest> interactionRequests) async {
    try {
      var endPoint = '${_baseUrl}AddInteraction';
      var sessionId = await AuthService().getSessionId();

      // change data to json list
      final List<Map<String, dynamic>> requestBody =
      interactionRequests.map((e) => e.toJson()).toList();

      final response = await dio.post(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'sessionId': sessionId
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Add failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error during sending interaction: $e');
      return false;
    }
  }
}
