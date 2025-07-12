import 'package:flutter/foundation.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/destination_types/destination_type.dart';
import 'package:travinhgo/models/marker/marker.dart';
import 'package:travinhgo/services/destination_service.dart';
import 'package:travinhgo/services/destination_type_service.dart';
import 'package:travinhgo/services/marker_service.dart';
import 'dart:developer' as developer;

class DestinationProvider with ChangeNotifier {
  final DestinationService _destinationService = DestinationService();
  final DestinationTypeService _destinationTypeService =
      DestinationTypeService();
  final MarkerService _markerService = MarkerService();

  List<Destination> _destinations = [];
  List<DestinationType> _destinationTypes = [];
  List<Marker> _markers = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Destination> get destinations => _destinations;
  List<DestinationType> get destinationTypes => _destinationTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllDestinations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _destinationService.getDestination(),
        _destinationTypeService.getMarkers(),
        _markerService.getMarkers(),
      ]);

      _destinations = results[0] as List<Destination>;
      _destinationTypes = results[1] as List<DestinationType>;
      _markers = results[2] as List<Marker>;

      // Link destination types with their markers
      for (var type in _destinationTypes) {
        try {
          type.marker = _markers.firstWhere((m) => m.id == type.markerId);
        } catch (e) {
          developer.log(
              'Marker not found for DestinationType ID: ${type.id}, Marker ID: ${type.markerId}',
              name: 'DestinationProvider');
        }
      }

      developer.log(
          'Fetched and linked ${_destinations.length} destinations, ${_destinationTypes.length} types, and ${_markers.length} markers.',
          name: 'DestinationProvider');
    } catch (e) {
      _errorMessage = "Failed to load destination data: ${e.toString()}";
      developer.log(_errorMessage!, name: 'DestinationProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DestinationType? getDestinationTypeById(String typeId) {
    try {
      return _destinationTypes.firstWhere((type) => type.id == typeId);
    } catch (e) {
      return null;
    }
  }
}
