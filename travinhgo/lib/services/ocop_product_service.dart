import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';

import '../models/ocop/ocop_product.dart';
import '../utils/constants.dart';

class OcopProductService {
  static final OcopProductService _instance = OcopProductService._internal();

  factory OcopProductService() {
    return _instance;
  }

  OcopProductService._internal() {
    dio.options.connectTimeout = const Duration(minutes: 3);

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  final String _baseUrl = '${Base_api}OcopProduct/';

  final Dio dio = Dio();

  Future<List<OcopProduct>> getOcopProduct() async {
    try {
      var endPoint = '${_baseUrl}GetAllOcopProduct';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<OcopProduct> ocopProducts =
            data.map((item) => OcopProduct.fromJson(item)).toList();
        return ocopProducts;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error during get destination list: $e');
      return [];
    }
  }

  Future<OcopProduct?> getOcopProductById(String id) async {
    try {
      var endPoint = '${_baseUrl}GetOcopProductById/${id}';

      final response = await dio.get(endPoint,
          options: Options(headers: {
            'Content-Type': 'application/json charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        dynamic data = response.data['data'];
        OcopProduct ocopProductDetail = OcopProduct.fromJson(data);
        return ocopProductDetail;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error during get ocop product list: $e');
      return null;
    }
  }

  Future<List<OcopProduct>> getOcopProductsByIds(List<String> ids) async {
    try{
      var endPoint = '${_baseUrl}GetOcopProductsByIds';

      final response = await dio.post(endPoint,
          data: ids,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          }));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<OcopProduct> ocopProducts =
        data.map((item) => OcopProduct.fromJson(item)).toList();
        return ocopProducts;
      } else {
        return [];
      }

    }catch(e) {
      debugPrint('Error during get ocop product list: $e');
      return [];
    }
  }
}
