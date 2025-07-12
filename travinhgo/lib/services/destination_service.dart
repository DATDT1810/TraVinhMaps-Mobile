import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/widgets.dart';
import 'package:travinhgo/models/destination/destination.dart';

import '../utils/env_config.dart';
import 'dart:developer' as developer;

class DestinationService {
  static final DestinationService _instance = DestinationService._internal();

  factory DestinationService() {
    return _instance;
  }

  DestinationService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${EnvConfig.apiBaseUrl}/TouristDestination/';

  final Dio dio = Dio();

  Future<List<Destination>> getDestination() async {
    try {
      var endPoint = '${_baseUrl}GetAllDestinations';
      developer.log('Start get destination list', name: 'destination_service');
      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        developer.log('destination_log: Received data: $data',
            name: 'destination_service');
        List<Destination> destinations =
            data.map((item) => Destination.fromJson(item)).toList();
        return destinations;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }

  Future<Destination?> getDestinationById(String id) async {
    try {
      var endPoint = '${_baseUrl}GetDestinationById/${id}';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        dynamic data = response.data['data'];
        developer.log('destination_log: Received data for id $id: $data',
            name: 'destination_service');
        Destination destinationDetail = Destination.fromJson(data);
        return destinationDetail;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return null;
    }
  }

  Future<List<Destination>> getDestinationsByIds(List<String> ids) async {
    try {
      var endPoint = '${_baseUrl}GetDestinationsByIds';

      final response = await dio.post(endPoint,
          data: ids,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        developer.log('destination_log: Received data for ids $ids: $data',
            name: 'destination_service');
        List<Destination> destinations =
            data.map((item) => Destination.fromJson(item)).toList();
        return destinations;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }
}
