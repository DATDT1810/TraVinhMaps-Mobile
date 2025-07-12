import 'package:here_sdk/core.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/models/marker/marker_type.dart';
import 'package:travinhgo/providers/destination_provider.dart';
import 'dart:developer' as developer;

import 'base_map_provider.dart';
import 'marker_map_provider.dart';

/// DestinationMapProvider handles the display of tourist destinations on the map
class DestinationMapProvider {
  final BaseMapProvider _baseMapProvider;
  final MarkerMapProvider _markerMapProvider;
  final DestinationProvider destinationProvider;

  bool _areDestinationsDisplayed = false;
  int _successfulMarkersCount = 0;
  List<Destination> _allDestinations = [];
  String? _activeFilter;

  // Constants
  static const String MARKER_TYPE_TOURIST_DESTINATION = "tourist_destination";

  DestinationMapProvider(
      this._baseMapProvider, this._markerMapProvider, this.destinationProvider);

  /// Displays all tourist destinations on the map
  /// Returns true if destination data was fetched for the first time.
  Future<bool> displayDestinationMarkers(String? filterTypeId) async {
    bool dataWasFetched = false;
    // Check if map controller is initialized
    if (_baseMapProvider.mapController == null) {
      developer.log(
          'Map controller is not initialized yet. Cannot display destination markers.',
          name: 'DestinationMapProvider');
      return dataWasFetched;
    }

    // If no filter change and markers are already displayed, do nothing
    if (filterTypeId == _activeFilter && _areDestinationsDisplayed) {
      developer.log(
          'Destinations for filter "$_activeFilter" are already displayed.',
          name: 'DestinationMapProvider');
      return dataWasFetched;
    }

    _activeFilter = filterTypeId;

    try {
      // Fetch data only if it hasn't been loaded yet
      if (_allDestinations.isEmpty) {
        developer.log('No destinations loaded. Fetching destinations...',
            name: 'DestinationMapProvider');
        await destinationProvider.fetchAllDestinations();
        _allDestinations = destinationProvider.destinations;
        dataWasFetched = true;
      }

      if (_allDestinations.isEmpty) {
        developer.log('No tourist destinations to display after fetching.',
            name: 'DestinationMapProvider');
        return dataWasFetched;
      }

      // Filter destinations based on the type ID
      final destinationsToDisplay = _activeFilter == null
          ? _allDestinations
          : _allDestinations
              .where((d) => d.destinationTypeId == _activeFilter)
              .toList();

      developer.log(
          'Starting to process ${destinationsToDisplay.length} destinations for filter: $_activeFilter',
          name: 'DestinationMapProvider');

      _successfulMarkersCount = 0;

      // Clear any existing destination markers first
      _markerMapProvider.clearMarkers([MARKER_TYPE_TOURIST_DESTINATION]);

      for (final destination in destinationsToDisplay) {
        developer.log('Processing destination: ${destination.name}',
            name: 'DestinationMapProvider');
        _addDestinationMarker(destination);
      }

      _areDestinationsDisplayed = true;
      developer.log(
          'Successfully displayed $_successfulMarkersCount out of ${destinationsToDisplay.length} tourist destinations for filter: $_activeFilter',
          name: 'DestinationMapProvider');
    } catch (e) {
      developer.log('Error displaying destination markers: $e',
          name: 'DestinationMapProvider');
    }
    return dataWasFetched;
  }

  void _addDestinationMarker(Destination destination) {
    try {
      if (destination.location.coordinates == null ||
          destination.location.coordinates!.length < 2) {
        developer.log(
            'Skipping destination ${destination.name}: No coordinates',
            name: 'DestinationMapProvider');
        return;
      }

      // Enhanced debugging - log raw coordinates
      developer.log(
          'Raw coordinates for ${destination.name}: ${destination.location.coordinates}',
          name: 'DestinationMapProvider');

      // Extract coordinates - API provides [latitude, longitude]
      final double latitude = destination.location.coordinates![0];
      final double longitude = destination.location.coordinates![1];

      // Check for invalid coordinate values
      if (longitude < -180 ||
          longitude > 180 ||
          latitude < -90 ||
          latitude > 90) {
        developer.log(
            'WARNING: Invalid coordinate values for ${destination.name}: [lon=${longitude}, lat=${latitude}]',
            name: 'DestinationMapProvider');
        return; // Skip this destination as coordinates are invalid
      }

      // Check if coordinates are within Vietnam's general boundaries
      bool isInVietnam = longitude >= 102 &&
          longitude <= 110 &&
          latitude >= 8 &&
          latitude <= 24;

      if (!isInVietnam) {
        developer.log(
            'WARNING: Coordinates for ${destination.name} appear to be outside Vietnam: [lon=${longitude}, lat=${latitude}]',
            name: 'DestinationMapProvider');
        // Continue anyway as the check might not be perfect
      }

      // Create GeoCoordinates with correct order (latitude, longitude)
      final coordinates = GeoCoordinates(latitude, longitude);

      developer.log(
          'Converted coordinates for ${destination.name}: lat=${coordinates.latitude}, lon=${coordinates.longitude}',
          name: 'DestinationMapProvider');

      // Get the destination type
      final destinationType = destinationProvider
          .getDestinationTypeById(destination.destinationTypeId);

      if (destinationType == null) {
        developer.log(
            'Destination type not found for ${destination.name} (typeId: ${destination.destinationTypeId})',
            name: 'DestinationMapProvider');
      } else {
        developer.log(
            'Found destination type: ${destinationType.name} for ${destination.name}',
            name: 'DestinationMapProvider');
      }

      // Determine the marker type using our enhanced methods
      MarkerType markerType;

      if (destinationType != null) {
        // If we have a marker ID from the destination type, use it
        if (destinationType.markerId != null &&
            destinationType.markerId.isNotEmpty) {
          markerType = MarkerType.fromMarkerId(destinationType.markerId);
          developer.log(
              'Using marker ID ${destinationType.markerId} for destination: ${destination.name}',
              name: 'DestinationMapProvider');
        }
        // Otherwise use the type name
        else if (destinationType.name != null &&
            destinationType.name.isNotEmpty) {
          markerType = MarkerType.fromTypeName(destinationType.name);
          developer.log(
              'Using type name ${destinationType.name} for destination: ${destination.name}',
              name: 'DestinationMapProvider');
        }
        // Fallback
        else {
          markerType = MarkerType.buildingDestination;
          developer.log(
              'Using fallback marker type for destination: ${destination.name}',
              name: 'DestinationMapProvider');
        }
      } else {
        // If no destination type found, use default
        markerType = MarkerType.buildingDestination;
        developer.log(
            'No destination type found, using default for: ${destination.name}',
            name: 'DestinationMapProvider');
      }

      // Get the asset path for this marker type
      final markerAsset = markerType.getAccessPath();

      developer.log(
          'Adding marker for ${destination.name} at lat: ${coordinates.latitude}, lon: ${coordinates.longitude} with asset: $markerAsset',
          name: 'DestinationMapProvider');

      // Create metadata
      final metadata = Metadata();
      metadata.setString("place_name", destination.name);
      metadata.setString(
          "place_category", destinationType?.name ?? "Destination");
      metadata.setString("destination_id", destination.id);

      // Add more detailed metadata for richer information when tapped
      if (destination.address != null) {
        metadata.setString("place_address", destination.address!);
      }

      // Add rating information
      metadata.setDouble("place_rating", destination.avarageRating);

      // Add description if available
      if (destination.description != null) {
        metadata.setString("place_description", destination.description!);
      }

      // Add contact information if available
      if (destination.contact != null) {
        if (destination.contact!.phone != null) {
          metadata.setString("place_phone", destination.contact!.phone!);
        }
        if (destination.contact!.email != null) {
          metadata.setString("place_email", destination.contact!.email!);
        }
        if (destination.contact!.website != null) {
          metadata.setString("place_website", destination.contact!.website!);
        }
      }

      // Add opening hours if available
      if (destination.openingHours != null) {
        String openingInfo = "";
        if (destination.openingHours!.openTime != null) {
          openingInfo += "Open: ${destination.openingHours!.openTime}";
        }
        if (destination.openingHours!.closeTime != null) {
          openingInfo += openingInfo.isNotEmpty ? ", " : "";
          openingInfo += "Close: ${destination.openingHours!.closeTime}";
        }
        if (openingInfo.isNotEmpty) {
          metadata.setString("place_opening_hours", openingInfo);
        }
      }

      // Add image URLs if available
      if (destination.images.isNotEmpty) {
        metadata.setString("place_images", destination.images.join(','));
      }

      // Store coordinates directly in metadata
      metadata.setDouble("place_lat", coordinates.latitude);
      metadata.setDouble("place_lon", coordinates.longitude);

      _markerMapProvider.addMarkerWithMetadata(
        coordinates,
        MARKER_TYPE_TOURIST_DESTINATION,
        metadata,
        customAsset: markerAsset,
      );

      _successfulMarkersCount++;
    } catch (e) {
      developer.log(
          'Error adding marker for destination ${destination.name}: $e',
          name: 'DestinationMapProvider');
    }
  }

  void filterDestinationMarkers(String? destinationTypeId) {
    displayDestinationMarkers(destinationTypeId);
  }

  /// Clears all destination markers from the map
  void clearDestinationMarkers() {
    _markerMapProvider.clearMarkers([MARKER_TYPE_TOURIST_DESTINATION]);
    _areDestinationsDisplayed = false;
    _successfulMarkersCount = 0;
    developer.log('Cleared all tourist destination markers.',
        name: 'DestinationMapProvider');
  }
}
