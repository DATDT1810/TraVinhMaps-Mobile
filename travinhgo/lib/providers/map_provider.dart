import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/search.dart';
import 'package:here_sdk/routing.dart' as here_sdk;
import 'package:geolocator/geolocator.dart';
import 'package:travinhgo/models/maps/geo_boundary_travinh.dart';
import 'package:travinhgo/utils/env_config.dart';
import 'dart:developer' as developer;
import 'dart:ui' show Color;

import '../Models/Maps/top_favorite_destination.dart';
import '../services/map_service.dart';
import 'ocop_product_provider.dart';

import 'map/base_map_provider.dart';
import 'map/marker_map_provider.dart';
import 'map/navigation_map_provider.dart';
import 'map/location_map_provider.dart';
import 'map/search_map_provider.dart';
import 'map/category_map_provider.dart';
import 'map/boundary_map_provider.dart';
import 'map/ocop_map_provider.dart';
import 'map/destination_map_provider.dart';
import 'destination_provider.dart';
import '../models/destination_types/destination_type.dart';

// Re-export the TransportMode enum for backward compatibility
export 'map/navigation_map_provider.dart' show TransportMode;

/// Main MapProvider that coordinates all the specialized sub-providers
class MapProvider extends ChangeNotifier {
  // Sub-providers
  late BaseMapProvider _baseMapProvider;
  late MarkerMapProvider _markerMapProvider;
  late NavigationMapProvider _navigationMapProvider;
  late LocationMapProvider _locationMapProvider;
  late SearchMapProvider _searchMapProvider;
  late CategoryMapProvider _categoryMapProvider;
  late BoundaryMapProvider _boundaryMapProvider;
  late OcopMapProvider _ocopMapProvider;
  late DestinationMapProvider _destinationMapProvider;

  // POI data storage
  String? lastPoiName;
  String? lastPoiCategory;
  GeoCoordinates? lastPoiCoordinates;
  Metadata? lastPoiMetadata; // Added to store full metadata for OCOP products
  bool showPoiPopup = false; // Flag to control POI popup visibility
  MapMarker? currentCustomMarker; // Reference to the current custom marker
  MapMarker? centerMarker; // Reference to the Tra Vinh center marker
  bool isCenterMarkerVisible =
      false; // Flag to track if center marker is visible

  // Constructor
  MapProvider() {
    // Initialize sub-providers in the right order
    _baseMapProvider = BaseMapProvider();
    _markerMapProvider = MarkerMapProvider(_baseMapProvider);
    _navigationMapProvider =
        NavigationMapProvider(_baseMapProvider, _markerMapProvider);
    _locationMapProvider =
        LocationMapProvider(_baseMapProvider, _markerMapProvider);
    _searchMapProvider =
        SearchMapProvider(_baseMapProvider, _markerMapProvider);
    _boundaryMapProvider = BoundaryMapProvider(_baseMapProvider);
    _categoryMapProvider = CategoryMapProvider(
        _baseMapProvider, _markerMapProvider,
        boundaryProvider: _boundaryMapProvider);

    // Register callback to update UI when route calculation is completed
    _navigationMapProvider.onRouteCalculated = () => notifyListeners();

    // Register callback for OCOP category selection
    _categoryMapProvider.onOcopCategorySelected = () {
      if (_ocopMapProvider != null) {
        developer.log(
            'data_ocop: OCOP category selected via filter, displaying products',
            name: 'MapProvider');
        // Always display products when the category is selected.
        // The deselection logic is handled within CategoryMapProvider.
        displayOcopProducts();
      }
    };

    _categoryMapProvider.onDestinationCategorySelected =
        (String? destinationTypeId) {
      if (_destinationMapProvider != null) {
        _destinationMapProvider.filterDestinationMarkers(destinationTypeId);
      }
    };
  }

  // Add getter for OCOP map provider
  OcopMapProvider get ocopMapProvider => _ocopMapProvider;

  // Method to initialize the sub-providers (called after splash screen)
  void initializeMapSubProviders(OcopProductProvider ocopProductProvider,
      DestinationProvider destinationProvider) {
    _ocopMapProvider = OcopMapProvider(
        _baseMapProvider, _markerMapProvider, ocopProductProvider);
    _destinationMapProvider = DestinationMapProvider(
        _baseMapProvider, _markerMapProvider, destinationProvider);

    // Pass destination types to the category provider
    if (destinationProvider.destinationTypes.isNotEmpty) {
      _categoryMapProvider
          .addDestinationTypeCategories(destinationProvider.destinationTypes);
      notifyListeners(); // Notify to rebuild category buttons
    }

    developer.log(
        'data_ocop: OcopMapProvider and DestinationMapProvider initialized',
        name: 'MapProvider');
  }

  // Forward property access to sub-providers for backward compatibility

  // Properties from BaseMapProvider
  HereMapController? get mapController => _baseMapProvider.mapController;
  String? get errorMessage => _baseMapProvider.errorMessage;
  set errorMessage(String? value) => _baseMapProvider.errorMessage = value;
  bool get isLoading => _baseMapProvider.isLoading;
  set isLoading(bool value) => _baseMapProvider.isLoading = value;
  GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _baseMapProvider.scaffoldMessengerKey;

  // Properties from CategoryMapProvider
  List<String> get categories => _categoryMapProvider.categories;
  int get selectedCategoryIndex => _categoryMapProvider.selectedCategoryIndex;
  bool get isCategoryActive => _categoryMapProvider.isCategoryActive;
  bool get isCategorySearching => _categoryMapProvider.isCategorySearching;

  // Properties from LocationMapProvider
  Position? get currentPosition => _locationMapProvider.currentPosition;

  // Properties from SearchMapProvider
  List<Suggestion> get searchSuggestions =>
      _searchMapProvider.searchSuggestions;
  bool get isSearching => _searchMapProvider.isSearching;

  // Properties from NavigationMapProvider
  bool get isRoutingMode => _navigationMapProvider.isRoutingMode;
  bool get isShowingDepartureInput =>
      _navigationMapProvider.isShowingDepartureInput;
  bool get isCalculatingRoute => _navigationMapProvider.isCalculatingRoute;
  String? get routeErrorMessage => _navigationMapProvider.routeErrorMessage;
  GeoCoordinates? get departureCoordinates =>
      _navigationMapProvider.departureCoordinates;
  String? get departureName => _navigationMapProvider.departureName;
  GeoCoordinates? get destinationCoordinates =>
      _navigationMapProvider.destinationCoordinates;
  String? get destinationName => _navigationMapProvider.destinationName;
  String? get destinationAddress => _navigationMapProvider.destinationAddress;
  int? get routeLengthInMeters => _navigationMapProvider.routeLengthInMeters;
  int? get routeDurationInSeconds =>
      _navigationMapProvider.routeDurationInSeconds;
  TransportMode get selectedTransportMode =>
      _navigationMapProvider.selectedTransportMode;
  Map<TransportMode, int> get routeDurations =>
      _navigationMapProvider.routeDurations;
  String? get departureAddress => _navigationMapProvider.departureAddress;

  // Properties from OcopMapProvider
  bool get isOcopDisplayed => _ocopMapProvider.isOcopDisplayed;

  // Other state variables
  int currentDestinationIndex = 0;
  bool destinationsLoaded = false;
  List<TopFavoriteDestination> topDestinations = [];
  final MapService _mapService = MapService();

  /// Initializes the map scene
  void initMapScene(HereMapController controller) {
    _baseMapProvider.initMapScene(controller, () async {
      // On successful map scene loading, just move to Tra Vinh center
      // without adding a marker
      refreshMap();
      _boundaryMapProvider.displayTraVinhBoundary();
      _setupGestureListeners();

      // Start preloading all category search data in background
      _preloadCategories();

      // Display tourist destinations. This also fetches data if needed,
      // which in turn updates the category buttons.
      await displayDestinationMarkers();

      // Now, display all other categories for the "All" view.
      // This includes default POIs and OCOP products.
      _categoryMapProvider.displayAllCategories();

      // Finally, set the UI state to show that the "All" button is selected.
      _categoryMapProvider.selectedCategoryIndex = 0;
      _categoryMapProvider.isCategoryActive = true;

      notifyListeners();
    });
  }

  /// Preload all category search data in the background
  Future<void> _preloadCategories() async {
    try {
      developer.log('Starting to preload all category data',
          name: 'MapProvider');
      await _categoryMapProvider.preloadAllCategories();
      developer.log('Successfully preloaded all category data',
          name: 'MapProvider');
    } catch (e) {
      developer.log('Error preloading category data: $e', name: 'MapProvider');
    }
  }

  /// Sets up tap listener for the map
  void _setupGestureListeners() {
    if (mapController == null) return;

    // Setup tap listener for POI and marker detection
    mapController!.gestures.tapListener = TapListener((Point2D touchPoint) {
      var geoCoordinates = mapController?.viewToGeoCoordinates(touchPoint);
      if (geoCoordinates != null) {
        handleMapTap(touchPoint, geoCoordinates);
      }
    });
  }

  /// Handle map tap events
  void handleMapTap(Point2D touchPoint, GeoCoordinates geoCoordinates) {
    // Remove center marker when tapping elsewhere on the map
    if (isCenterMarkerVisible) {
      toggleCenterMarker(); // Use the toggle method to properly handle marker removal
    }

    // In routing mode with departure input active, use the tapped location as departure
    if (isRoutingMode && isShowingDepartureInput) {
      _navigationMapProvider.addDepartureMarker(
          geoCoordinates, "Selected location");
      return;
    }

    // Create a rectangle around the touch point for picking
    Point2D originInPixels = Point2D(touchPoint.x - 25, touchPoint.y - 25);
    Size2D sizeInPixels = Size2D(50, 50);
    Rectangle2D rectangle = Rectangle2D(originInPixels, sizeInPixels);

    // Create a list of map content types to pick from
    List<MapSceneMapPickFilterContentType> contentTypesToPickFrom = [
      MapSceneMapPickFilterContentType.mapItems, // For custom markers
      MapSceneMapPickFilterContentType.mapContent // For embedded POIs
    ];

    // Create filter with the content types
    MapSceneMapPickFilter filter =
        MapSceneMapPickFilter(contentTypesToPickFrom);

    // Use the pick API to find markers and POIs at the touch point
    mapController!.pick(filter, rectangle, (MapPickResult? pickResult) {
      if (pickResult == null) {
        _handleEmptyTap(geoCoordinates);
        return;
      }

      bool handled = false;

      // First check for custom map markers
      if (pickResult.mapItems != null &&
          pickResult.mapItems!.markers.isNotEmpty) {
        handled = _handleMarkerTap(pickResult.mapItems!.markers.first);
      }

      // If no marker was handled, then check for embedded POIs
      if (!handled && pickResult.mapContent != null) {
        PickMapContentResult pickMapContentResult = pickResult.mapContent!;

        // Check for picked places (Carto POIs)
        if (pickMapContentResult.pickedPlaces.isNotEmpty) {
          _handlePickedCartoPOIs(pickMapContentResult.pickedPlaces);
          handled = true;
        }
      }

      // If nothing was picked, handle as an empty tap
      if (!handled) {
        _handleEmptyTap(geoCoordinates);
      }
    });
  }

  // Handle tap on a custom marker
  bool _handleMarkerTap(MapMarker tappedMarker) {
    // Check if this is a marker with metadata
    if (tappedMarker.metadata != null) {
      // Get place information from marker metadata for all markers
      Map<String, String>? placeInfo =
          _markerMapProvider.getPlaceInfoFromMarker(tappedMarker);

      if (placeInfo != null) {
        // Store reference to the tapped marker if it's a custom marker
        if (tappedMarker == _markerMapProvider.currentCustomMarker) {
          currentCustomMarker = tappedMarker;
        }

        // Show POI popup with the place information
        showCategoryMarkerPopup(
            placeInfo, tappedMarker.coordinates, tappedMarker.metadata);
        return true;
      }
    }
    return false;
  }

  // Handle tap on empty map area
  void _handleEmptyTap(GeoCoordinates geoCoordinates) {
    // Close any existing popup
    if (showPoiPopup) {
      closePoiPopup();
    }

    // Add custom marker at the tapped location
    addMarker(geoCoordinates, MarkerMapProvider.MARKER_TYPE_CUSTOM);
  }

  // Handle picked Carto POIs (embedded POIs)
  void _handlePickedCartoPOIs(List<PickedPlace> cartoPOIList) {
    if (cartoPOIList.isEmpty) return;

    // Get the topmost picked place
    PickedPlace topmostPickedPlace = cartoPOIList.first;

    // Extract information
    String poiName = (topmostPickedPlace.name != null &&
            topmostPickedPlace.name!.trim().isNotEmpty)
        ? topmostPickedPlace.name!
        : 'Lat: ${topmostPickedPlace.coordinates.latitude.toStringAsFixed(6)}, Lon: ${topmostPickedPlace.coordinates.longitude.toStringAsFixed(6)}';
    Map<String, String> placeInfo = {
      'name': poiName,
      'category':
          topmostPickedPlace.placeCategoryId.toString() ?? "Unnamed Category",
    };

    // Add coordinates to the place info
    placeInfo['latitude'] = topmostPickedPlace.coordinates.latitude.toString();
    placeInfo['longitude'] =
        topmostPickedPlace.coordinates.longitude.toString();

    // Try to extract more information if available
    try {
      // Log detailed information about the picked POI for debugging
      developer.log('Picked POI details: [0m${topmostPickedPlace.toString()}',
          name: 'MapProvider');

      // Try to get place categories if available
      if (topmostPickedPlace.toString().contains("categories")) {
        placeInfo['category'] = "HERE POI";
      }
    } catch (e) {
      developer.log('Error extracting additional POI details: $e',
          name: 'MapProvider');
    }

    // Log the picked POI
    developer.log(
        'Picked embedded POI: ${placeInfo['name']} at ${placeInfo['latitude']}, ${placeInfo['longitude']}',
        name: 'MapProvider');

    // Show POI popup with the place information
    showCategoryMarkerPopup(placeInfo, topmostPickedPlace.coordinates);
  }

  /// Shows a popup with information about a place from a category marker or embedded POI
  void showCategoryMarkerPopup(
      Map<String, String> placeInfo, GeoCoordinates coordinates,
      [Metadata? metadata]) {
    // Set the POI info
    lastPoiName = placeInfo['name'];
    lastPoiCategory = placeInfo['category'];
    lastPoiCoordinates = coordinates;
    lastPoiMetadata = metadata; // Store full metadata
    showPoiPopup = true;

    // Move camera to the POI location with closer zoom for better visibility
    moveCamera(coordinates, 500);

    // Log the POI being displayed
    developer.log('Showing POI popup for: ${lastPoiName} (${lastPoiCategory})',
        name: 'MapProvider');

    // Notify listeners to update the UI
    notifyListeners();
  }

  /// Closes the POI popup
  void closePoiPopup() {
    showPoiPopup = false;
    lastPoiMetadata = null; // Clear metadata when closing
    notifyListeners();
  }

  /// Toggles display of OCOP products on the map
  void toggleOcopProductDisplay() {
    _ocopMapProvider.toggleOcopProductDisplay();
    notifyListeners();
  }

  /// Display OCOP products on the map
  void displayOcopProducts() {
    _ocopMapProvider.displayOcopProducts();
    notifyListeners();
  }

  /// Clear OCOP products from the map
  void clearOcopProducts() {
    _ocopMapProvider.clearOcopMarkers();
    notifyListeners();
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    _categoryMapProvider.updateSelectedCategory(index);
    notifyListeners();
  }

  /// Get category icon by index
  String getCategoryIcon(int index) {
    return _categoryMapProvider.getCategoryIcon(index);
  }

  /// Get the category icon based on selection state
  String getCategoryIconForState(int index, bool isSelected) {
    return _categoryMapProvider.getCategoryIconForState(index, isSelected);
  }

  /// Checks if a category's icon is tintable
  bool isCategoryTintable(int index) {
    return _categoryMapProvider.isCategoryTintable(index);
  }

  /// Gets the current user position
  Future<void> getCurrentPosition() async {
    await _locationMapProvider.getCurrentPosition();
    notifyListeners();
  }

  /// Moves the camera to a specified location with a given zoom distance
  void moveCamera(GeoCoordinates coordinates, [double? distanceInMeters]) {
    _baseMapProvider.moveCamera(coordinates, distanceInMeters);
  }

  /// Refreshes the map to show Tra Vinh province
  void refreshMap() {
    // Move to Tra Vinh center without adding a marker
    _boundaryMapProvider.moveToTraVinhCenter();
  }

  /// Toggle the center marker visibility
  void toggleCenterMarker() {
    // Define Tra Vinh center coordinates directly
    final centerCoordinates = GeoCoordinates(
        BoundaryMapProvider.traVinhLat, BoundaryMapProvider.traVinhLon);

    // If center marker is visible, remove it
    if (isCenterMarkerVisible) {
      if (centerMarker != null) {
        _markerMapProvider.removeMarker(centerMarker!);
        centerMarker = null;
      }
      isCenterMarkerVisible = false;
      developer.log('Center marker removed', name: 'MapProvider');
    } else {
      // Add center marker if not visible
      // Create a custom marker type specifically for the center marker
      _markerMapProvider.addMarker(
          centerCoordinates, MarkerMapProvider.MARKER_TYPE_CUSTOM,
          customAsset: "assets/images/markers/marker.png");

      // Get reference to the marker that was just added
      centerMarker = _markerMapProvider.currentCustomMarker;

      // Safety check to ensure marker was created
      if (centerMarker != null) {
        isCenterMarkerVisible = true;
        developer.log('Center marker added', name: 'MapProvider');
      } else {
        developer.log('Failed to create center marker', name: 'MapProvider');
      }
    }

    notifyListeners();
  }

  /// Searches for locations based on query text
  Future<void> searchLocations(String query) async {
    await _searchMapProvider.searchLocations(query);
    notifyListeners();
  }

  /// Handle selection of search suggestion
  void selectSearchSuggestion(Suggestion suggestion) {
    _searchMapProvider.selectSearchSuggestion(suggestion);
    notifyListeners();
  }

  /// Clears current search suggestions
  void clearSearchResults() {
    _searchMapProvider.clearSearchResults();
    notifyListeners();
  }

  /// Searches for departure locations
  Future<void> searchDepartureLocations(String query) async {
    await _searchMapProvider.searchDepartureLocations(query);
    notifyListeners();
  }

  /// Select a departure suggestion
  void selectDepartureSuggestion(Suggestion suggestion) {
    _searchMapProvider.selectDepartureSuggestion(suggestion,
        (coordinates, name) {
      _navigationMapProvider.addDepartureMarker(coordinates, name);
      notifyListeners();
    });
  }

  /// Sets transport mode for routing
  void setTransportMode(TransportMode mode) {
    _navigationMapProvider.setTransportMode(mode);
    notifyListeners();
  }

  /// Sets up the routing mode
  void startRouting(GeoCoordinates coordinates, String name) {
    _navigationMapProvider.startRouting(coordinates, name);

    // Update addresses using reverse geocoding
    _navigationMapProvider.updateAddressesFromCoordinates();

    notifyListeners();
  }

  /// Cancels routing mode
  void cancelRouting() {
    _navigationMapProvider.cancelRouting();
    notifyListeners();
  }

  /// Adds a departure marker
  void addDepartureMarker(GeoCoordinates coordinates, String name) {
    _navigationMapProvider.addDepartureMarker(coordinates, name);
    notifyListeners();
  }

  /// Use Tra Vinh center as departure point
  void useTraVinhCenterAsDeparture() {
    _navigationMapProvider.useTraVinhCenterAsDeparture();
    notifyListeners();
  }

  /// Swap departure and destination
  void swapDepartureAndDestination() {
    _navigationMapProvider.swapDepartureAndDestination();
    notifyListeners();
  }

  /// Shows the departure input field
  void showDepartureInput() {
    _navigationMapProvider.showDepartureInput();
    notifyListeners();
  }

  /// Hides the departure input UI
  void hideDepartureInput() {
    _navigationMapProvider.hideDepartureInput();
    notifyListeners();
  }

  /// Adds a marker of a specific type
  Future<void> addMarker(GeoCoordinates coordinates, String markerType,
      {String? customAsset}) async {
    await _markerMapProvider.addMarker(coordinates, markerType,
        customAsset: customAsset);

    // Update currentCustomMarker reference if it's a custom marker
    if (markerType == MarkerMapProvider.MARKER_TYPE_CUSTOM) {
      currentCustomMarker = _markerMapProvider.currentCustomMarker;
    }

    notifyListeners();
  }

  /// Gets place info from a marker
  Map<String, String>? getPlaceInfoFromMarker(MapMarker marker) {
    return _markerMapProvider.getPlaceInfoFromMarker(marker);
  }

  /// Clears markers of specified types
  void clearMarkers(List<String> markerTypes) {
    _markerMapProvider.clearMarkers(markerTypes);
    notifyListeners();
  }

  /// Updates the current destination index and moves to that destination
  void updateCurrentDestination(int index) {
    currentDestinationIndex = index;

    // Move to the destination on the map
    if (topDestinations.isNotEmpty && topDestinations[index].id != null) {
      moveToDestination(topDestinations[index].id!);
    }

    notifyListeners();
  }

  /// Moves to a specific destination
  void moveToDestination(String id) {
    // Get coordinates for the destination
    final coordinates = _mapService.getDestinationCoordinates()[id];
    if (coordinates == null) return;

    // Create a GeoCoordinates object and move camera with more zoom
    moveCamera(GeoCoordinates(coordinates[0], coordinates[1]), 500.0);
  }

  /// Loads top favorite destinations from the service
  Future<void> loadTopDestinations() async {
    try {
      isLoading = true;
      notifyListeners();

      final destinations = await _mapService.getTopFavoriteDestinations();

      topDestinations = destinations;
      destinationsLoaded = true;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error loading top destinations: $e', name: 'MapProvider');
      isLoading = false;
      destinationsLoaded = false;
      topDestinations = [];
      notifyListeners();
    }
  }

  /// Cleans up map resources
  void cleanupMapResources() {
    _markerMapProvider.cleanupMarkerResources();
    _navigationMapProvider.cleanupNavigationResources();
    _categoryMapProvider.cleanupCategoryResources();
    _boundaryMapProvider.cleanupBoundaryResources();
    if (_ocopMapProvider != null) {
      _ocopMapProvider.clearOcopMarkers();
    }
    if (_destinationMapProvider != null) {
      _destinationMapProvider.clearDestinationMarkers();
    }
    _baseMapProvider.cleanupMapResources();

    // Clear POI data
    lastPoiName = null;
    lastPoiCategory = null;
    lastPoiCoordinates = null;
    lastPoiMetadata = null;
    showPoiPopup = false;
    currentCustomMarker = null;
  }

  /// Completely disposes HERE SDK resources
  Future<void> disposeHERESDK() async {
    await _baseMapProvider.disposeHERESDK();
  }

  /// Update addresses for both departure and destination points
  Future<void> updateAddresses() async {
    await _navigationMapProvider.updateAddressesFromCoordinates();
    notifyListeners();
  }

  /// Displays tourist destinations on the map
  Future<void> displayDestinationMarkers() async {
    if (_destinationMapProvider != null) {
      final bool dataWasFetched =
          await _destinationMapProvider.displayDestinationMarkers(null);
      if (dataWasFetched &&
          _destinationMapProvider
              .destinationProvider.destinationTypes.isNotEmpty) {
        _categoryMapProvider.addDestinationTypeCategories(
            _destinationMapProvider.destinationProvider.destinationTypes);
        notifyListeners();
      }
    }
  }
}
