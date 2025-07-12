import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'dart:developer' as developer;
import 'dart:async';

import 'base_map_provider.dart';
import 'marker_map_provider.dart';
import 'boundary_map_provider.dart';
import '../../models/destination_types/destination_type.dart';
import '../../models/marker/marker_type.dart' as mt;

/// CategoryType defines types of POIs that can be displayed on the map
/// with their corresponding user-friendly names and PlaceCategory IDs
class CategoryType {
  final String name; // User-friendly name for UI display
  final String categoryId; // PlaceCategory ID for HERE SDK
  final String markerAsset; // Path to the marker asset
  final String iconAsset; // Path to the icon asset for category buttons
  final String? selectedIconAsset;
  final bool isTintable;
  final bool isDestinationCategory;
  final String? destinationTypeId;

  const CategoryType({
    required this.name,
    required this.categoryId,
    required this.markerAsset,
    required this.iconAsset,
    this.selectedIconAsset,
    this.isTintable = false,
    this.isDestinationCategory = false,
    this.destinationTypeId,
  });
}

/// CategoryMapProvider handles all category filtering and POI display functionality
class CategoryMapProvider {
  // Reference to other providers
  final BaseMapProvider baseMapProvider;
  final MarkerMapProvider markerMapProvider;
  late final BoundaryMapProvider boundaryMapProvider;

  // Callback when OCOP category is selected
  Function()? onOcopCategorySelected;
  Function(String?)? onDestinationCategorySelected;

  // Category state variables
  int selectedCategoryIndex = 0;
  bool isCategoryActive = true;
  bool isCategorySearching = false; // Flag to track category search progress
  bool isPreloadingCategories = false; // Flag to track preloading progress
  bool hasPreloadedCategories =
      false; // Flag to indicate if categories are preloaded

  // Search engine
  SearchEngine? _searchEngine;

  // Search radius visualization
  MapPolygon? searchRadiusCircle;

  // Store Place objects by their coordinates (as string key)
  final Map<String, Place> _placeObjects = {};

  // Cache for category search results - maps category ID to a list of places
  final Map<String, List<Place>> _categoryCache = {};

  // Constants
  static const double traVinhLat = 9.9349;
  static const double traVinhLon = 106.3452;
  static const double searchRadiusInMeters = 10000; // 10km radius for searching

  // Get mapController from baseMapProvider
  HereMapController? get mapController => baseMapProvider.mapController;

  final List<CategoryType> _baseCategories = [
    CategoryType(
      name: "All",
      categoryId: "", // Empty for "All" category
      markerAsset: "assets/images/markers/marker.png",
      iconAsset: "assets/images/navigations/map.png",
      isTintable: true,
    ),
    CategoryType(
      name: "OCOP",
      categoryId: "ocop_products", // Custom ID for OCOP products
      markerAsset: "assets/images/map/ocop.png",
      iconAsset: "assets/images/map/ocop.png",
      isTintable: false,
    ),
    CategoryType(
      name: "Hotels",
      categoryId: PlaceCategory.accommodationHotelMotel,
      markerAsset: "assets/images/markers/hotel.png",
      iconAsset: "assets/images/markers/hotel.png",
    ),
    CategoryType(
      name: "Restaurants",
      categoryId: PlaceCategory.eatAndDrinkRestaurant,
      markerAsset: "assets/images/markers/restaurant.png",
      iconAsset: "assets/images/markers/restaurant.png",
    ),
    CategoryType(
      name: "Cafes",
      categoryId: PlaceCategory.eatAndDrinkCoffeeTea,
      markerAsset: "assets/images/markers/coffee-shop.png",
      iconAsset: "assets/images/markers/coffee-shop.png",
    ),
    CategoryType(
      name: "Fuel",
      categoryId: PlaceCategory.businessAndServicesFuelingStation,
      markerAsset: "assets/images/markers/gas-station.png",
      iconAsset: "assets/images/markers/gas-station.png",
    ),
    CategoryType(
      name: "ATMs",
      categoryId: PlaceCategory.businessAndServicesAtm,
      markerAsset: "assets/images/markers/atm.png",
      iconAsset: "assets/images/markers/atm.png",
    ),
    CategoryType(
      name: "Banks",
      categoryId: PlaceCategory.businessAndServicesBanking,
      markerAsset: "assets/images/markers/bank.png",
      iconAsset: "assets/images/markers/bank.png",
    ),
    CategoryType(
      name: "Schools",
      categoryId: PlaceCategory.facilitiesEducation,
      markerAsset: "assets/images/markers/education.png",
      iconAsset: "assets/images/markers/education.png",
    ),
    CategoryType(
      name: "Hospitals",
      categoryId: PlaceCategory.facilitiesHospitalHealthcare,
      markerAsset: "assets/images/markers/hospital.png",
      iconAsset: "assets/images/markers/hospital.png",
    ),
    CategoryType(
      name: "Police",
      categoryId: PlaceCategory.businessAndServicesPoliceFireEmergency,
      markerAsset: "assets/images/markers/police-station.png",
      iconAsset: "assets/images/markers/police-station.png",
    ),
    CategoryType(
      name: "Bus Stops",
      categoryId: PlaceCategory.transportPublic,
      markerAsset: "assets/images/markers/bus.png",
      iconAsset: "assets/images/markers/bus.png",
    ),
    CategoryType(
      name: "Stores",
      categoryId: PlaceCategory.shoppingConvenienceStore,
      markerAsset: "assets/images/markers/supermarket.png",
      iconAsset: "assets/images/markers/supermarket.png",
    ),
  ];
  List<CategoryType> availableCategories = [];

  // Categories for filter buttons - populated from availableCategories Vietnamese names
  List<String> get categories =>
      availableCategories.map((cat) => cat.name).toList();

  // Constructor
  CategoryMapProvider(this.baseMapProvider, this.markerMapProvider,
      {BoundaryMapProvider? boundaryProvider}) {
    initializeSearchEngine();
    boundaryMapProvider =
        boundaryProvider ?? BoundaryMapProvider(baseMapProvider);
    availableCategories = List.from(_baseCategories);
  }

  /// Initialize the search engine for category searches
  void initializeSearchEngine() {
    try {
      _searchEngine = SearchEngine();
      developer.log('Category search engine initialized',
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to initialize category search engine: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Get category icon by index
  String getCategoryIcon(int index) {
    if (index < 0 || index >= availableCategories.length) {
      return "assets/images/navigations/map.png"; // Default icon
    }
    return availableCategories[index].iconAsset;
  }

  /// Get the category icon based on selection state
  String getCategoryIconForState(int index, bool isSelected) {
    if (index < 0 || index >= availableCategories.length) {
      return "assets/images/navigations/map.png"; // Default icon
    }
    final category = availableCategories[index];
    if (isSelected && category.selectedIconAsset != null) {
      return category.selectedIconAsset!;
    }
    return category.iconAsset;
  }

  /// Checks if a category's icon is tintable
  bool isCategoryTintable(int index) {
    if (index < 0 || index >= availableCategories.length) {
      return false;
    }
    return availableCategories[index].isTintable;
  }

  /// Preload all category search results for caching
  Future<void> preloadAllCategories() async {
    if (isPreloadingCategories || hasPreloadedCategories) {
      return; // Already preloading or preloaded
    }

    try {
      isPreloadingCategories = true;
      developer.log('Starting to preload all categories',
          name: 'CategoryMapProvider');

      // Skip the first category which is "All"
      for (int i = 1; i < availableCategories.length; i++) {
        await preloadCategorySearch(availableCategories[i]);
      }

      hasPreloadedCategories = true;
      isPreloadingCategories = false;
      developer.log('All categories preloaded successfully',
          name: 'CategoryMapProvider');
    } catch (e) {
      isPreloadingCategories = false;
      developer.log('Error preloading categories: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Preload a single category search
  Future<void> preloadCategorySearch(CategoryType categoryType) async {
    if (_searchEngine == null) {
      developer.log('Search engine is null', name: 'CategoryMapProvider');
      return;
    }

    if (_categoryCache.containsKey(categoryType.categoryId)) {
      developer.log('Category ${categoryType.name} already cached',
          name: 'CategoryMapProvider');
      return; // Already cached
    }

    try {
      developer.log('Preloading category: ${categoryType.name}',
          name: 'CategoryMapProvider');

      // Create a list with the selected category
      List<PlaceCategory> categoryList = [];
      categoryList.add(PlaceCategory(categoryType.categoryId));

      // Create a search area centered at Tra Vinh
      var queryArea =
          CategoryQueryArea.withCenter(GeoCoordinates(traVinhLat, traVinhLon));

      CategoryQuery categoryQuery =
          CategoryQuery.withCategoriesInArea(categoryList, queryArea);

      // Configure search options for Vietnamese language and 30 max results
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode = LanguageCode.viVn;
      searchOptions.maxItems = 30;

      // Create completer for async handling
      final completer = Completer<void>();

      // Execute the search
      _searchEngine!.searchByCategory(categoryQuery, searchOptions,
          (SearchError? searchError, List<Place>? places) async {
        if (searchError != null) {
          developer.log('Category preload error: $searchError',
              name: 'CategoryMapProvider');
          completer.complete(); // Complete even on error
          return;
        }

        // If places is null or empty, try with English language
        if (places == null || places.isEmpty) {
          SearchOptions englishOptions = SearchOptions();
          englishOptions.languageCode = LanguageCode.enUs;
          englishOptions.maxItems = 30;

          developer.log(
              'No Vietnamese results, trying English search for category ${categoryType.name}',
              name: 'CategoryMapProvider');

          _searchEngine!.searchByCategory(categoryQuery, englishOptions,
              (SearchError? secondError, List<Place>? englishPlaces) {
            if (secondError != null) {
              developer.log('English category preload error: $secondError',
                  name: 'CategoryMapProvider');
              completer.complete();
              return;
            }

            if (englishPlaces != null && englishPlaces.isNotEmpty) {
              // Store in cache
              _categoryCache[categoryType.categoryId] = englishPlaces;
              developer.log(
                  'Cached ${englishPlaces.length} places for category: ${categoryType.name} (English)',
                  name: 'CategoryMapProvider');
            } else {
              // Store empty list to avoid repeated searches
              _categoryCache[categoryType.categoryId] = [];
              developer.log('No places found for category ${categoryType.name}',
                  name: 'CategoryMapProvider');
            }
            completer.complete();
          });
        } else {
          // Cache the Vietnamese results
          _categoryCache[categoryType.categoryId] = places;
          developer.log(
              'Cached ${places.length} places for category: ${categoryType.name} (Vietnamese)',
              name: 'CategoryMapProvider');
          completer.complete();
        }
      });

      // Return the future from the completer
      return completer.future;
    } catch (e) {
      developer.log('Error preloading category ${categoryType.name}: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Updates the selected category index and performs category search
  void updateSelectedCategory(int index) {
    // Check if the user is clicking the already selected category
    if (selectedCategoryIndex == index && isCategoryActive) {
      // Toggle off the category - turning off the filter
      isCategoryActive = false;

      // Clear any existing category search markers
      markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);

      // Remove search radius circle if it exists
      removeSearchRadiusCircle();
      return;
    }

    // Either selecting a new category or re-enabling a previously toggled off category
    isCategoryActive = true;

    // Update the category index
    selectedCategoryIndex = index;

    // Clear any existing category search markers
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);

    // Remove search radius circle if it exists
    removeSearchRadiusCircle();

    // If "All" category is selected (index 0), display all categories
    if (index == 0) {
      displayAllCategories();
      if (onDestinationCategorySelected != null) {
        onDestinationCategorySelected!(null);
      }
    } else {
      // For any selected category (not "All"), show the search radius circle
      addSearchRadiusCircle();

      // Get the selected category
      final selectedCategory = availableCategories[index];

      if (selectedCategory.isDestinationCategory) {
        if (onDestinationCategorySelected != null) {
          onDestinationCategorySelected!(selectedCategory.destinationTypeId);
        }
        return; // Early return for destination categories
      }

      // For any other category, we should hide the API-based destinations.
      // We can do this by calling the filter with an empty string, which will result
      // in no destinations being displayed.
      if (onDestinationCategorySelected != null) {
        onDestinationCategorySelected!('');
      }

      // Special handling for OCOP category
      if (selectedCategory.categoryId == "ocop_products") {
        // Notify the MapProvider to show OCOP products
        if (onOcopCategorySelected != null) {
          developer.log('Triggering OCOP callback',
              name: 'CategoryMapProvider');
          onOcopCategorySelected!();
        } else {
          developer.log('OCOP callback not set', name: 'CategoryMapProvider');
        }
      } else {
        // Display places for other categories
        displayCategoryPlaces(selectedCategory);
      }
    }
  }

  /// Display all category places from cache
  void displayAllCategories() {
    // Skip the first category which is "All"
    for (int i = 1; i < availableCategories.length; i++) {
      final category = availableCategories[i];
      if (category.isDestinationCategory) {
        continue;
      }
      // Special handling for OCOP products
      if (availableCategories[i].categoryId == "ocop_products") {
        if (onOcopCategorySelected != null) {
          developer.log('Showing OCOP products as part of All categories',
              name: 'CategoryMapProvider');
          onOcopCategorySelected!();
        }
        continue; // Skip to next category since we've handled OCOP specially
      }

      // Handle other regular categories
      displayCategoryPlaces(availableCategories[i], isFromAllCategories: true);
    }
  }

  /// Display places for a specific category using cached results when available
  void displayCategoryPlaces(CategoryType categoryType,
      {bool isFromAllCategories = false}) {
    // Check if we have cached results for this category
    if (_categoryCache.containsKey(categoryType.categoryId)) {
      List<Place> places = _categoryCache[categoryType.categoryId]!;

      // If we have cached places, display them
      if (places.isNotEmpty) {
        developer.log(
            'Displaying ${places.length} cached places for ${categoryType.name}',
            name: 'CategoryMapProvider');
        _displayCategoryPlaces(places, categoryType);
        return;
      }
    }

    // If we don't have cached places, search for them (with loading indicator)
    if (!isPreloadingCategories) {
      searchLocationsByCategory(categoryType,
          isFromAllCategories: isFromAllCategories);
    }
  }

  /// Display places on the map
  void _displayCategoryPlaces(List<Place> places, CategoryType categoryType) {
    for (Place place in places) {
      if (place.geoCoordinates != null) {
        // Check if the place is inside Tra Vinh boundary before displaying it
        _filterAndAddMarker(place, categoryType);
      }
    }
  }

  /// Filter place by boundary and add marker if inside Tra Vinh
  void _filterAndAddMarker(Place place, CategoryType categoryType) async {
    // Check if the place is within Tra Vinh boundary
    bool isInTraVinh = await boundaryMapProvider
        .isPointInTraVinhBoundary(place.geoCoordinates!);

    if (!isInTraVinh) {
      developer.log(
          'Filtered out place outside Tra Vinh boundary: ${place.title}',
          name: 'CategoryMapProvider');
      return;
    }

    // Create rich metadata for POI display
    Metadata metadata = Metadata();
    metadata.setString("place_name", place.title ?? "Unknown Place");
    metadata.setString("place_category", categoryType.name);

    // Store address information
    if (place.address != null) {
      if (place.address!.addressText != null) {
        metadata.setString("place_address", place.address!.addressText!);
      }

      // Store additional address details if available
      if (place.address!.city != null) {
        metadata.setString("place_city", place.address!.city!);
      }
      if (place.address!.state != null) {
        metadata.setString("place_state", place.address!.state!);
      }
    }

    // Store coordinates
    metadata.setDouble("place_lat", place.geoCoordinates!.latitude);
    metadata.setDouble("place_lon", place.geoCoordinates!.longitude);

    // Store category ID for filtering
    metadata.setString("place_category_id", categoryType.categoryId);

    // Store a reference to identify this is a HERE SDK Place
    metadata.setString("is_here_place", "true");

    // Generate a unique key for this place based on its coordinates
    String placeKey =
        "${place.geoCoordinates!.latitude},${place.geoCoordinates!.longitude}";

    // Store the Place object for later retrieval (if not already stored)
    if (!_placeObjects.containsKey(placeKey)) {
      _placeObjects[placeKey] = place;
    }

    // Add phone information if available
    try {
      if (place.details != null && place.details!.contacts != null) {
        // Extract phone number using proper HERE SDK structure
        String? phoneNumber = _extractPhoneNumber(place);
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          metadata.setString("place_phone", phoneNumber);
        }
      }
    } catch (e) {
      developer.log('Failed to extract phone number: $e',
          name: 'CategoryMapProvider');
    }

    // Add marker with metadata
    markerMapProvider.addMarkerWithMetadata(
        place.geoCoordinates!, MarkerMapProvider.MARKER_TYPE_CATEGORY, metadata,
        customAsset: categoryType.markerAsset);
  }

  /// Search for locations of all available categories
  void searchAllCategories() {
    // Skip the first category which is "All"
    for (int i = 1; i < availableCategories.length; i++) {
      searchLocationsByCategory(availableCategories[i],
          isFromAllCategories: true);
    }
  }

  /// Search for locations based on a category
  Future<void> searchLocationsByCategory(CategoryType categoryType,
      {bool isFromAllCategories = false}) async {
    if (_searchEngine == null) {
      developer.log('Search engine is null', name: 'CategoryMapProvider');
      return;
    }

    try {
      // Only set loading state if not part of "All" categories search
      if (!isFromAllCategories) {
        isCategorySearching = true;
      }

      // Create a list with the selected category
      List<PlaceCategory> categoryList = [];
      categoryList.add(PlaceCategory(categoryType.categoryId));

      // Create a search area centered at Tra Vinh
      var queryArea =
          CategoryQueryArea.withCenter(GeoCoordinates(traVinhLat, traVinhLon));

      CategoryQuery categoryQuery =
          CategoryQuery.withCategoriesInArea(categoryList, queryArea);

      // Configure search options for Vietnamese language and 30 max results
      SearchOptions searchOptions = SearchOptions();
      searchOptions.languageCode = LanguageCode.viVn;
      searchOptions.maxItems = 30;

      developer.log(
          'Searching for category: ${categoryType.name} with ID: ${categoryType.categoryId}',
          name: 'CategoryMapProvider');

      // Execute the search
      _searchEngine!.searchByCategory(categoryQuery, searchOptions,
          (SearchError? searchError, List<Place>? places) async {
        if (searchError != null) {
          developer.log('Category search error: $searchError',
              name: 'CategoryMapProvider');
          if (!isFromAllCategories) {
            isCategorySearching = false;
          }
          return;
        }

        // If places is null or empty, try with English language
        if (places == null || places.isEmpty) {
          SearchOptions englishOptions = SearchOptions();
          englishOptions.languageCode = LanguageCode.enUs;
          englishOptions.maxItems = 30;

          developer.log(
              'No Vietnamese results, trying English search for category',
              name: 'CategoryMapProvider');

          _searchEngine!.searchByCategory(categoryQuery, englishOptions,
              (SearchError? secondError, List<Place>? englishPlaces) {
            if (!isFromAllCategories) {
              isCategorySearching = false;
            }

            if (secondError != null) {
              developer.log('English category search error: $secondError',
                  name: 'CategoryMapProvider');
              return;
            }

            if (englishPlaces != null && englishPlaces.isNotEmpty) {
              // Cache the results
              _categoryCache[categoryType.categoryId] = englishPlaces;
              _handleCategorySearchResults(englishPlaces, categoryType);
            } else {
              // Cache empty list to avoid repeated searches
              _categoryCache[categoryType.categoryId] = [];
              developer.log('No places found for category',
                  name: 'CategoryMapProvider');
            }
          });
        } else {
          // Process Vietnamese results
          if (!isFromAllCategories) {
            isCategorySearching = false;
          }

          // Cache the results
          _categoryCache[categoryType.categoryId] = places;
          _handleCategorySearchResults(places, categoryType);
        }
      });
    } catch (e) {
      if (!isFromAllCategories) {
        isCategorySearching = false;
        developer.log('Error in searchLocationsByCategory: $e',
            name: 'CategoryMapProvider');
      }
    }
  }

  /// Handle the results from category search
  void _handleCategorySearchResults(
      List<Place> places, CategoryType categoryType) async {
    developer.log(
        'Found ${places.length} places for category: ${categoryType.name}',
        name: 'CategoryMapProvider');

    _displayCategoryPlaces(places, categoryType);
  }

  /// Helper method to extract phone number from Place object
  String? _extractPhoneNumber(Place place) {
    try {
      if (place.details == null || place.details!.contacts == null) {
        return null;
      }

      // Different versions of the HERE SDK might have different structures
      // Try to access phone information using available properties
      var contacts = place.details!.contacts;

      // Try to get phone from the place details without assuming specific structure
      if (contacts.toString().contains('phone')) {
        // If there's phone data in the contacts, try to extract it from the debug string
        String contactsStr = contacts.toString();
        RegExp phonePattern = RegExp(r'phone[:\s]+([0-9+\-() ]+)');
        Match? match = phonePattern.firstMatch(contactsStr);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.trim();
        }
      }

      return null;
    } catch (e) {
      developer.log('Error extracting phone number: $e',
          name: 'CategoryMapProvider');
      return null;
    }
  }

  /// Adds a circle showing the search radius around Tra Vinh center
  void addSearchRadiusCircle() {
    if (mapController == null) return;

    try {
      // Remove any existing search radius circle
      removeSearchRadiusCircle();

      // Create a GeoCircle with the specified radius
      GeoCircle circle = GeoCircle(
          GeoCoordinates(traVinhLat, traVinhLon), searchRadiusInMeters);

      // Convert the GeoCircle to a GeoPolygon
      GeoPolygon circlePolygon = GeoPolygon.withGeoCircle(circle);

      // Create a MapPolygon with semi-transparent blue fill and outline
      searchRadiusCircle = MapPolygon.withOutlineColorAndOutlineWidthInPixels(
          circlePolygon,
          Color.fromARGB(40, 0, 122, 255), // Semi-transparent blue fill
          Color.fromARGB(180, 0, 122, 255), // More opaque blue outline
          2.0 // 2 pixel outline width
          );

      // Add the circle to the map
      mapController!.mapScene.addMapPolygon(searchRadiusCircle!);

      developer.log(
          'Added search radius circle with ${searchRadiusInMeters / 1000}km radius',
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to add search radius circle: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Removes the search radius circle from the map
  void removeSearchRadiusCircle() {
    if (mapController == null || searchRadiusCircle == null) return;

    try {
      mapController!.mapScene.removeMapPolygon(searchRadiusCircle!);
      searchRadiusCircle = null;

      developer.log('Removed search radius circle',
          name: 'CategoryMapProvider');
    } catch (e) {
      developer.log('Failed to remove search radius circle: $e',
          name: 'CategoryMapProvider');
    }
  }

  /// Gets the HERE Place object by coordinates if available
  Place? getPlaceByCoordinates(GeoCoordinates coordinates) {
    String key = "${coordinates.latitude},${coordinates.longitude}";
    return _placeObjects[key];
  }

  /// Clears the stored Place objects
  void clearPlaceObjects() {
    _placeObjects.clear();
  }

  /// Cleanup category resources
  void cleanupCategoryResources() {
    removeSearchRadiusCircle();
    clearPlaceObjects();
    markerMapProvider.clearMarkers([MarkerMapProvider.MARKER_TYPE_CATEGORY]);
    developer.log('Category resources cleaned up', name: 'CategoryMapProvider');
  }

  void addDestinationTypeCategories(List<DestinationType> destinationTypes) {
    // Create a temporary list to hold the new categories
    List<CategoryType> newCategories = [];

    // Create CategoryType objects from destination types
    for (final destType in destinationTypes) {
      if (destType.name.isNotEmpty) {
        final markerType = mt.MarkerType.fromTypeName(destType.name);
        final iconPath = markerType.getAccessPath();

        newCategories.add(CategoryType(
          name: destType.name,
          categoryId: destType.id, // Use the ID for unique identification
          markerAsset: iconPath,
          iconAsset: iconPath,
          isDestinationCategory: true,
          destinationTypeId: destType.id,
        ));
      }
    }

    // Add the new categories after the base categories, avoiding duplicates
    final uniqueNewCategories = newCategories
        .where((newCat) => !availableCategories
            .any((cat) => cat.categoryId == newCat.categoryId))
        .toList();

    if (uniqueNewCategories.isNotEmpty) {
      // Insert new categories after "All" and "OCOP"
      availableCategories.insertAll(2, uniqueNewCategories);
    }

    developer.log(
        'Updated available categories with ${uniqueNewCategories.length} new destination types.',
        name: 'CategoryMapProvider');
  }
}
