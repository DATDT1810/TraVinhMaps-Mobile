import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/tip/tip.dart';
import '../utils/env_config.dart';

class TipService {
  static final TipService _instance = TipService._internal();

  factory TipService() {
    return _instance;
  }

  TipService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/CommunityTips/';

  final Dio dio = Dio();

  Future<List<Tip>> getTips() async {
    try {
      var endPoint = '${_baseUrl}GetAllTipActive';
      final response = await dio.get(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<Tip> tips = data.map((item) => Tip.fromJson(item)).toList();
        return tips;
      }
      return [];
    } catch (e) {
      debugPrint('Error during get tip list: $e');
      return [];
    }
  }
}
