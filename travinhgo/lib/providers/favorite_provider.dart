import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/Models/favorite/favorite.dart';

import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/models/ocop/ocop_product.dart';
import '../services/destination_service.dart';
import '../services/favorite_service.dart';
import '../services/local_specialtie_service.dart';
import '../services/ocop_product_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Favorite> _favorites = [];
  final List<Destination> _destinationList = [];
  final List<LocalSpecialties> _localSpecialteList = [];
  final List<OcopProduct> _ocopProductList = [];

  List<Favorite> get favorites => _favorites;

  List<Destination> get destinationList => _destinationList;

  List<LocalSpecialties> get localSpecialteList => _localSpecialteList;

  List<OcopProduct> get ocopProductList => _ocopProductList;

  Future<void> fetchFavorites() async {
    try {
      List<Favorite> favoriteFetch = await FavoriteService().getFavorites();
      _favorites.clear();
      _favorites.addAll(favoriteFetch);

      List<String> destinationIds = [];
      List<String> ocopIds = [];
      List<String> localIds = [];

      for (var item in _favorites) {
        switch (item.itemType) {
          case 'Destination':
            destinationIds.add(item.itemId);
            break;
          case 'OcopProduct':
            ocopIds.add(item.itemId);
            break;
          case 'LocalSpecialties':
            localIds.add(item.itemId);
            break;
        }
      }

      // Chuẩn bị future cho từng loại
      final destinationFuture = destinationIds.isNotEmpty
          ? DestinationService().getDestinationsByIds(destinationIds)
          : Future.value(<Destination>[]);

      final ocopFuture = ocopIds.isNotEmpty
          ? OcopProductService().getOcopProductsByIds(ocopIds)
          : Future.value(<OcopProduct>[]);

      final localFuture = localIds.isNotEmpty
          ? LocalSpecialtieService().getLocalSpecialtiesByIds(localIds)
          : Future.value(<LocalSpecialties>[]);

      // Chờ 3 future hoàn tất song song
      final results = await Future.wait([
        destinationFuture,
        ocopFuture,
        localFuture,
      ]);

      // Gán kết quả vào danh sách tương ứng
      _destinationList
        ..clear()
        ..addAll(results[0] as List<Destination>);

      _ocopProductList
        ..clear()
        ..addAll(results[1] as List<OcopProduct>);

      _localSpecialteList
        ..clear()
        ..addAll(results[2] as List<LocalSpecialties>);

      debugPrint('-------------------------------------------');
      for (var destination in _destinationList) {
        debugPrint('name: ${destination.name}, ID: ${destination.id}');
      }


      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch favorite: $e');
    }
  }

  Future<void> toggleDestinationFavorite(Destination item) async {
    final index = _favorites
        .indexWhere((f) => f.itemId == item.id && f.itemType == "Destination");
    if (index != -1) {
      _favorites.removeAt(index);
      _destinationList.remove(item);
      await FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "Destination");
      _favorites.add(fav);
      _destinationList.add(item);
      await FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  Future<void> toggleOcopFavorite(OcopProduct item) async {
    final index = _favorites
        .indexWhere((f) => f.itemId == item.id && f.itemType == "OcopProduct");
    if (index != -1) {
      _favorites.removeAt(index);
      _ocopProductList.remove(item);
      await FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "OcopProduct");
      _favorites.add(fav);
      _ocopProductList.add(item);
      await FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  Future<void> toggleLocalSpecialtiesFavorite(LocalSpecialties item) async {
    final index = _favorites.indexWhere(
        (f) => f.itemId == item.id && f.itemType == "LocalSpecialties");
    if (index != -1) {
      _favorites.removeAt(index);
      _localSpecialteList.remove(item);
      await FavoriteService().removeFavoriteList(item.id);
    } else {
      final fav = Favorite(itemId: item.id, itemType: "LocalSpecialties");
      _favorites.add(fav);
      _localSpecialteList.add(item);
      await FavoriteService().addFavoriteList(fav);
    }
    notifyListeners();
  }

  bool isExist(String id) {
    return _favorites.any((fav) => fav.itemId == id);
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
