import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../Models/itinerary_plan/itinerary_plan.dart';
import '../utils/env_config.dart';

class ItineraryPlanService {
  static final ItineraryPlanService _instance =
      ItineraryPlanService._internal();

  factory ItineraryPlanService() {
    return _instance;
  }

  ItineraryPlanService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/ItineraryPlan/';

  final Dio dio = Dio();

  Future<List<ItineraryPlan>> getItineraryPlan() async {
    try {
      var endPoint = '${_baseUrl}GetAllItineraryPlanWithDestination';

      final response = await dio.get(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<ItineraryPlan> itineraryPlans =
            data.map((item) => ItineraryPlan.fromJson(item)).toList();
        return itineraryPlans;
      }
      return [];
    } catch (e) {
      debugPrint('Error during get itinerary plan list: $e');
      return [];
    }
  }
}
