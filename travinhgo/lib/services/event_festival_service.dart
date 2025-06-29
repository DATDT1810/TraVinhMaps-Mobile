import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/event_festival/event_and_festival.dart';
import '../utils/env_config.dart';

class EventFestivalService {
  static final EventFestivalService _instance = EventFestivalService._internal();

  factory EventFestivalService() {
    return _instance;
  }

  EventFestivalService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/EventAndFestival/';

  final Dio dio = Dio();

  Future<List<EventAndFestival>> getDestination() async {
    try {
      var endPoint = '${_baseUrl}GetAllEventAndFestinal';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<EventAndFestival> eventAndFestivals =
        data.map((item) => EventAndFestival.fromJson(item)).toList();
        return eventAndFestivals;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get event and festival list: $e');
      return [];
    }
  }

  Future<EventAndFestival?> getDestinationById(String id) async {
    try {
      var endPoint = '${_baseUrl}GetEventAndFestivalById/${id}';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        dynamic data = response.data['data'];
        EventAndFestival eventAndFestivalDetail = EventAndFestival.fromJson(data);
        return eventAndFestivalDetail;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get event and festival list: $e');
      return null;
    }
  }
}