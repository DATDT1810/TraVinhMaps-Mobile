import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'dart:developer' as developer;

import 'base_map_provider.dart';

/// MarkerMapProvider handles all marker-related operations
class MarkerMapProvider {
  // Reference to the base map provider
  final BaseMapProvider baseMapProvider;

  // Marker size constants
  static const double markerMinSize = 60.0;
  static const double markerMaxSize = 180.0;
  static const double minZoomLevel = 5.0;
  static const double maxZoomLevel = 20.0;

  // Marker types
  static const String MARKER_TYPE_LOCATION = "location";
  static const String MARKER_TYPE_DESTINATION = "destination";
  static const String MARKER_TYPE_CUSTOM = "custom";
  static const String MARKER_TYPE_CATEGORY = "category";
  static const String MARKER_TYPE_DEPARTURE = "departure";
  static const String MARKER_TYPE_ROUTE_DESTINATION = "route_destination";
  static const String MARKER_TYPE_TOURIST_DESTINATION = "tourist_destination";

  // Marker collections
  final List<MapMarker> destinationMarkers = [];
  final List<MapMarker> customMarkers = [];
  final List<MapMarker> categoryMarkers = [];
  final List<MapMarker> touristDestinationMarkers = [];
  MapMarker? currentLocationMarker;
  MapMarker? currentCustomMarker;
  MapMarker? departureMarker;
  MapMarker? routeDestinationMarker;

  // Constructor
  MarkerMapProvider(this.baseMapProvider) {
    // Set up zoom level change listener
    baseMapProvider.onZoomLevelChanged = _onZoomLevelChanged;
  }

  // Get the map controller from base provider
  HereMapController? get mapController => baseMapProvider.mapController;

  /// Adds a marker to the map of a specific type
  Future<void> addMarker(GeoCoordinates coordinates, String markerType,
      {String? customAsset}) async {
    if (mapController == null) return;

    try {
      // Handle marker type-specific logic
      if (markerType == MARKER_TYPE_CUSTOM) {
        // Clear any existing custom markers
        clearMarkers([MARKER_TYPE_CUSTOM]);
      }

      // Get marker image
      MapImage markerImage =
          await _getMarkerImage(markerType, null, customAsset);

      // Create new marker
      MapMarker mapMarker = MapMarker(coordinates, markerImage);
      mapMarker.drawOrder = 1000; // Ensure marker is on top

      // Add marker to map
      mapController?.mapScene.addMapMarker(mapMarker);

      // Store marker reference based on type
      switch (markerType) {
        case MARKER_TYPE_LOCATION:
          if (currentLocationMarker != null) {
            mapController!.mapScene.removeMapMarker(currentLocationMarker!);
          }
          currentLocationMarker = mapMarker;
          break;
        case MARKER_TYPE_CUSTOM:
          customMarkers.add(mapMarker);
          currentCustomMarker = mapMarker;
          break;
        case MARKER_TYPE_DESTINATION:
          destinationMarkers.add(mapMarker);
          break;
        case MARKER_TYPE_CATEGORY:
          categoryMarkers.add(mapMarker);
          break;
        case MARKER_TYPE_DEPARTURE:
          departureMarker = mapMarker;
          break;
        case MARKER_TYPE_ROUTE_DESTINATION:
          routeDestinationMarker = mapMarker;
          break;
      }

      // Log the coordinates where marker was placed
      developer.log(
          '$markerType marker added at: ${coordinates.latitude}, ${coordinates.longitude}',
          name: 'MarkerMapProvider');
    } catch (e) {
      developer.log('Failed to add marker: $e', name: 'MarkerMapProvider');
    }
  }

  /// Get a marker image with the specified size
  Future<MapImage> _getMarkerImage(String markerType,
      [int? customSize, String? customAsset]) async {
    String assetPath;
    int size = customSize ?? _calculateMarkerSize();

    // Determine asset path based on marker type or custom asset
    if (customAsset != null) {
      assetPath = customAsset;
      developer.log('Using custom asset path: $assetPath',
          name: 'MarkerMapProvider');
    } else {
      switch (markerType) {
        case MARKER_TYPE_LOCATION:
          // Use a more visible location marker
          assetPath = 'assets/images/navigations/destination_point.png';
          // Override size for location marker to make it more visible
          size = 72;
          break;
        case MARKER_TYPE_CUSTOM:
          // Use a distinctive marker for custom taps
          assetPath = 'assets/images/markers/marker.png';
          // Make custom markers slightly larger
          size = 78;
          break;
        case MARKER_TYPE_TOURIST_DESTINATION:
          // Use a default marker for tourist destinations if no custom asset provided
          assetPath = 'assets/images/markers/marker.png';
          size = 78; // Make tourist destination markers slightly larger
          break;
        case MARKER_TYPE_DESTINATION:
        case MARKER_TYPE_CATEGORY:
        case MARKER_TYPE_DEPARTURE:
        case MARKER_TYPE_ROUTE_DESTINATION:
        default:
          assetPath = 'assets/images/markers/marker.png';
          break;
      }
      developer.log('Using default asset path for $markerType: $assetPath',
          name: 'MarkerMapProvider');
    }

    try {
      // Check if the asset file exists
      try {
        await rootBundle.load(assetPath);
        developer.log('Asset exists: $assetPath', name: 'MarkerMapProvider');
      } catch (assetError) {
        developer.log('Asset not found: $assetPath, using fallback marker',
            name: 'MarkerMapProvider');
        assetPath = 'assets/images/markers/marker.png';
      }

      // Create marker image directly - no caching needed as HERE SDK handles this
      return MapImage.withFilePathAndWidthAndHeight(assetPath, size, size);
    } catch (e) {
      developer.log('Failed to create marker image: $e',
          name: 'MarkerMapProvider');

      // Fallback to a default size if the specified size fails
      try {
        return MapImage.withFilePathAndWidthAndHeight(assetPath, 80, 80);
      } catch (finalError) {
        developer.log('CRITICAL: Even default marker failed: $finalError',
            name: 'MarkerMapProvider');
        throw Exception('Could not create any marker image');
      }
    }
  }

  /// Calculate the appropriate marker size based on zoom level
  int _calculateMarkerSize() {
    double zoomFactor = (baseMapProvider.currentZoomLevel - minZoomLevel) /
        (maxZoomLevel - minZoomLevel);
    return (markerMinSize + zoomFactor * (markerMaxSize - markerMinSize))
        .round();
  }

  /// Handles zoom level changes
  void _onZoomLevelChanged(double newZoomLevel) {
    // Update marker sizes if needed
    if (currentCustomMarker != null && customMarkers.isNotEmpty) {
      _updateMarkerSize();
    }
  }

  /// Updates the marker size based on current zoom level
  void _updateMarkerSize() async {
    if (mapController == null || currentCustomMarker == null) return;

    // Calculate new marker size based on zoom level
    int markerSize = _calculateMarkerSize();

    try {
      // Remove the current marker
      mapController!.mapScene.removeMapMarker(currentCustomMarker!);

      // Create a new marker with updated size
      MapImage markerImage =
          await _getMarkerImage(MARKER_TYPE_CUSTOM, markerSize);

      // Create a new marker with the same coordinates but new size
      MapMarker newMarker =
          MapMarker(currentCustomMarker!.coordinates, markerImage);
      newMarker.drawOrder = 1000;

      // Add the new marker and update reference
      mapController!.mapScene.addMapMarker(newMarker);

      // Update markers list
      if (customMarkers.isNotEmpty) {
        customMarkers.clear();
      }
      customMarkers.add(newMarker);
      currentCustomMarker = newMarker;
    } catch (e) {
      developer.log('Failed to update marker size: $e',
          name: 'MarkerMapProvider');
    }
  }

  /// Adds a marker to the map with associated metadata
  Future<void> addMarkerWithMetadata(
      GeoCoordinates coordinates, String markerType, Metadata metadata,
      {String? customAsset}) async {
    if (mapController == null) {
      developer.log('Cannot add marker: Map controller is null',
          name: 'MarkerMapProvider');
      return;
    }

    // Validate coordinates - skip markers with invalid coordinates
    if (coordinates.latitude < -90 ||
        coordinates.latitude > 90 ||
        coordinates.longitude < -180 ||
        coordinates.longitude > 180) {
      developer.log(
          'Invalid coordinates for marker: lat=${coordinates.latitude}, lon=${coordinates.longitude}. Skipping marker.',
          name: 'MarkerMapProvider');
      return;
    }

    try {
      // Log the marker creation attempt
      developer.log(
          'Attempting to add $markerType marker at: ${coordinates.latitude}, ${coordinates.longitude}' +
              (customAsset != null ? ' with custom asset: $customAsset' : ''),
          name: 'MarkerMapProvider');

      // Get marker image
      MapImage? markerImage;
      try {
        markerImage = await _getMarkerImage(markerType, null, customAsset);
        developer.log('Successfully created marker image',
            name: 'MarkerMapProvider');
      } catch (imageError) {
        developer.log('Failed to create marker image: $imageError',
            name: 'MarkerMapProvider');
        // Try with default marker as fallback
        try {
          markerImage = await _getMarkerImage(
              markerType, null, 'assets/images/markers/marker.png');
          developer.log('Using fallback marker image',
              name: 'MarkerMapProvider');
        } catch (fallbackError) {
          developer.log('Even fallback marker failed: $fallbackError',
              name: 'MarkerMapProvider');
          return; // Cannot proceed without an image
        }
      }

      // Create new marker
      MapMarker mapMarker = MapMarker(coordinates, markerImage);
      mapMarker.drawOrder = 1000; // Ensure marker is on top
      mapMarker.metadata = metadata; // Set metadata

      // Add text to marker for CATEGORY type markers and TOURIST_DESTINATION markers
      if (markerType == MARKER_TYPE_CATEGORY ||
          markerType == MARKER_TYPE_TOURIST_DESTINATION) {
        // Get place name from metadata
        String? placeName = metadata.getString("place_name");
        if (placeName != null && placeName.isNotEmpty) {
          // Apply marker text and styling
          _applyMarkerTextStyle(mapMarker, placeName);
        }

        // Set metadata for the marker to be used when tapped
        mapMarker.metadata = metadata;
      }

      // Add marker to map
      try {
        mapController?.mapScene.addMapMarker(mapMarker);
        developer.log('Successfully added marker to map scene',
            name: 'MarkerMapProvider');
      } catch (addError) {
        developer.log('Failed to add marker to map scene: $addError',
            name: 'MarkerMapProvider');
        return;
      }

      // Store marker reference based on type
      if (markerType == MARKER_TYPE_CATEGORY) {
        categoryMarkers.add(mapMarker);
      } else if (markerType == MARKER_TYPE_TOURIST_DESTINATION) {
        // Store tourist destination markers
        touristDestinationMarkers.add(mapMarker);
        developer.log(
            'Added tourist destination marker: ${metadata.getString("place_name") ?? "Unknown"}',
            name: 'MarkerMapProvider');
      }

      // Log the coordinates where marker was placed
      developer.log(
          '$markerType marker added at: ${coordinates.latitude}, ${coordinates.longitude}',
          name: 'MarkerMapProvider');
    } catch (e) {
      developer.log('Failed to add marker with metadata: $e',
          name: 'MarkerMapProvider');
    }
  }

  /// Apply text style to marker
  void _applyMarkerTextStyle(MapMarker mapMarker, String text) {
    try {
      // Get current text style from marker
      MapMarkerTextStyle textStyleCurrent = mapMarker.textStyle;
      MapMarkerTextStyle textStyleNew = mapMarker.textStyle;

      // Set text properties - increased size per user request
      double textSizeInPixels =
          32; // Increased from 16 to 24 for better visibility
      double textOutlineSizeInPixels =
          5; // Increased outline for better contrast

      // Define text placement options
      List<MapMarkerTextStylePlacement> placements = [];
      placements.add(
          MapMarkerTextStylePlacement.bottom); // Primary placement at bottom
      placements
          .add(MapMarkerTextStylePlacement.top); // Fall back to top if needed

      // Don't allow overlapping for better readability
      mapMarker.isOverlapAllowed = false;

      try {
        // Create new text style
        textStyleNew = MapMarkerTextStyle.make(
            textSizeInPixels,
            Color.fromARGB(255, 0, 0, 0), // Black text
            textOutlineSizeInPixels,
            Color.fromARGB(255, 255, 255, 255), // White outline
            placements);

        // Apply text and style to marker
        mapMarker.text = text;
        mapMarker.textStyle = textStyleNew;

        developer.log('Applied text style to marker: $text',
            name: 'MarkerMapProvider');
      } on MapMarkerTextStyleInstantiationException catch (e) {
        developer.log("TextStyle error: ${e.error.name}",
            name: 'MarkerMapProvider');
      }
    } catch (e) {
      developer.log('Failed to apply marker text style: $e',
          name: 'MarkerMapProvider');
    }
  }

  /// Removes markers of specified types
  void clearMarkers(List<String> markerTypes) {
    if (mapController == null) return;

    for (String type in markerTypes) {
      switch (type) {
        case MARKER_TYPE_CUSTOM:
          for (var marker in customMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          customMarkers.clear();
          currentCustomMarker = null;
          break;
        case MARKER_TYPE_DESTINATION:
          for (var marker in destinationMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          destinationMarkers.clear();
          break;
        case MARKER_TYPE_LOCATION:
          if (currentLocationMarker != null) {
            mapController!.mapScene.removeMapMarker(currentLocationMarker!);
            currentLocationMarker = null;
          }
          break;
        case MARKER_TYPE_CATEGORY:
          for (var marker in categoryMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          categoryMarkers.clear();
          break;
        case MARKER_TYPE_DEPARTURE:
          if (departureMarker != null) {
            mapController!.mapScene.removeMapMarker(departureMarker!);
            departureMarker = null;
          }
          break;
        case MARKER_TYPE_ROUTE_DESTINATION:
          if (routeDestinationMarker != null) {
            mapController!.mapScene.removeMapMarker(routeDestinationMarker!);
            routeDestinationMarker = null;
          }
          break;
        case MARKER_TYPE_TOURIST_DESTINATION:
          for (var marker in touristDestinationMarkers) {
            mapController!.mapScene.removeMapMarker(marker);
          }
          touristDestinationMarkers.clear();
          developer.log('Cleared all tourist destination markers',
              name: 'MarkerMapProvider');
          break;
      }
    }
  }

  /// Returns a Map with place information from a MapMarker using stored metadata
  Map<String, String>? getPlaceInfoFromMarker(MapMarker marker) {
    if (marker.metadata == null) return null;

    Map<String, String> placeInfo = {};

    try {
      String? name = marker.metadata?.getString("place_name");
      String? category = marker.metadata?.getString("place_category");
      String? address = marker.metadata?.getString("place_address");
      String? city = marker.metadata?.getString("place_city");
      String? state = marker.metadata?.getString("place_state");
      String? phone = marker.metadata?.getString("place_phone");

      // Handle both product and destination images
      String? productImages = marker.metadata?.getString("product_images");
      String? placeImages = marker.metadata?.getString("place_images");
      String? images = placeImages ?? productImages;

      // Handle both product and destination ratings
      String? productRating = marker.metadata?.getString("product_rating");
      double? placeRating = marker.metadata?.getDouble("place_rating");
      String? rating =
          placeRating != null ? placeRating.toString() : productRating;

      // Get additional destination details
      String? description = marker.metadata?.getString("place_description");
      String? email = marker.metadata?.getString("place_email");
      String? website = marker.metadata?.getString("place_website");
      String? openingHours = marker.metadata?.getString("place_opening_hours");
      String? destinationId = marker.metadata?.getString("destination_id");

      // Get coordinates directly from metadata if available, otherwise use marker coordinates
      double? lat = marker.metadata?.getDouble("place_lat");
      double? lon = marker.metadata?.getDouble("place_lon");

      if (name != null) placeInfo['name'] = name;
      if (category != null) placeInfo['category'] = category;

      // Build complete address
      String fullAddress = "";
      if (address != null) fullAddress = address;
      if (city != null && !fullAddress.contains(city)) {
        fullAddress = fullAddress.isEmpty ? city : "$fullAddress, $city";
      }
      if (state != null && !fullAddress.contains(state)) {
        fullAddress = fullAddress.isEmpty ? state : "$fullAddress, $state";
      }

      if (fullAddress.isNotEmpty) placeInfo['address'] = fullAddress;
      if (phone != null) placeInfo['phone'] = phone;

      // Add coordinates
      placeInfo['latitude'] = (lat ?? marker.coordinates.latitude).toString();
      placeInfo['longitude'] = (lon ?? marker.coordinates.longitude).toString();

      // Add destination/OCOP specific data if available
      if (images != null) placeInfo['images'] = images;
      if (rating != null) placeInfo['rating'] = rating;
      if (description != null) placeInfo['description'] = description;
      if (email != null) placeInfo['email'] = email;
      if (website != null) placeInfo['website'] = website;
      if (openingHours != null) placeInfo['opening_hours'] = openingHours;
      if (destinationId != null) placeInfo['destination_id'] = destinationId;

      return placeInfo;
    } catch (e) {
      developer.log('Error getting place info from marker: $e',
          name: 'MarkerMapProvider');
      return null;
    }
  }

  /// Clean up all marker resources
  void cleanupMarkerResources() {
    clearMarkers([
      MARKER_TYPE_LOCATION,
      MARKER_TYPE_DESTINATION,
      MARKER_TYPE_CUSTOM,
      MARKER_TYPE_CATEGORY,
      MARKER_TYPE_DEPARTURE,
      MARKER_TYPE_ROUTE_DESTINATION,
      MARKER_TYPE_TOURIST_DESTINATION
    ]);

    developer.log('All marker resources have been cleaned up',
        name: 'MarkerMapProvider');
  }

  /// Remove a specific marker from the map
  void removeMarker(MapMarker marker) {
    if (mapController == null) return;

    try {
      mapController!.mapScene.removeMapMarker(marker);

      // Remove from appropriate collection if needed
      if (marker == currentLocationMarker) {
        currentLocationMarker = null;
      } else if (marker == currentCustomMarker) {
        customMarkers.remove(marker);
        currentCustomMarker = null;
      } else if (marker == departureMarker) {
        departureMarker = null;
      } else if (marker == routeDestinationMarker) {
        routeDestinationMarker = null;
      } else if (categoryMarkers.contains(marker)) {
        categoryMarkers.remove(marker);
      } else if (destinationMarkers.contains(marker)) {
        destinationMarkers.remove(marker);
      } else if (touristDestinationMarkers.contains(marker)) {
        touristDestinationMarkers.remove(marker);
      }

      developer.log('Marker removed from map', name: 'MarkerMapProvider');
    } catch (e) {
      developer.log('Failed to remove marker: $e', name: 'MarkerMapProvider');
    }
  }
}
