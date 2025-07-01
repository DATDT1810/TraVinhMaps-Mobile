import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:travinhgo/services/auth_service.dart';

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
  
  Future<void> sendInteraction() async {
    try{
      var endPoint = '${_baseUrl}AddInteraction';
      var sessionId = await AuthService().getSessionId();
      
    }catch(e) {
      debugPrint('Error during sending interaction: $e');
    }
  }
  
}