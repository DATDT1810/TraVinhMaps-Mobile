enum MarkerType {
  ocopProduct,
  buildingDestination,
  naturalDestination,
  religiousBuilding,
  naturalLandScape,
  monumentsAndMuseums,
  folkLore,
  ecology,
  eventAndFestival,
  localSpecialties;

  String getAccessPath() {
    switch (this) {
      case MarkerType.ocopProduct:
        return 'assets/images/map/ocop.png';
      case MarkerType.naturalLandScape:
        return 'assets/images/map/natural_landscape.png';
      case MarkerType.monumentsAndMuseums:
        return 'assets/images/map/monumentsAndMuseums.png';
      case MarkerType.religiousBuilding:
        return 'assets/images/map/religious_building.png';
      case MarkerType.folkLore:
        return 'assets/images/map/folklore.png';
      case MarkerType.ecology:
        return 'assets/images/map/ecology.png';
      case MarkerType.eventAndFestival:
        return 'assets/images/map/eventAndFestival.png';
      case MarkerType.localSpecialties:
        return 'assets/images/map/local_specialties.png';
      case MarkerType.buildingDestination:
        return 'assets/images/map/monumentsAndMuseums.png';
      case MarkerType.naturalDestination:
        return 'assets/images/map/natural_landscape.png';
      default:
        return 'assets/images/markers/marker.png';
    }
  }

  // Create a MarkerType from a marker ID
  static MarkerType fromMarkerId(String markerId) {
    switch (markerId) {
      case 'marker_monuments':
      case 'marker_building':
        return MarkerType.monumentsAndMuseums;
      case 'marker_landscape':
      case 'marker_natural':
        return MarkerType.naturalLandScape;
      case 'marker_religious':
        return MarkerType.religiousBuilding;
      case 'marker_folklore':
        return MarkerType.folkLore;
      case 'marker_ecology':
        return MarkerType.ecology;
      case 'marker_event':
      case 'marker_festival':
        return MarkerType.eventAndFestival;
      case 'marker_specialties':
      case 'marker_local':
        return MarkerType.localSpecialties;
      case 'marker_ocop':
        return MarkerType.ocopProduct;
      default:
        return MarkerType.buildingDestination;
    }
  }

  // Create a MarkerType from a destination type name (handles both English and Vietnamese)
  static MarkerType fromTypeName(String typeName) {
    // Convert to lowercase for case-insensitive comparison
    String name = typeName.toLowerCase();

    if (name.contains('di tích') ||
        name.contains('bảo tàng') ||
        name.contains('monuments') ||
        name.contains('museums')) {
      return MarkerType.monumentsAndMuseums;
    } else if (name.contains('cảnh quan') ||
        name.contains('thiên nhiên') ||
        name.contains('natural') ||
        name.contains('landscape')) {
      return MarkerType.naturalLandScape;
    } else if (name.contains('tôn giáo') ||
        name.contains('religious') ||
        name.contains('building')) {
      return MarkerType.religiousBuilding;
    } else if (name.contains('văn hóa') ||
        name.contains('dân gian') ||
        name.contains('folklore')) {
      return MarkerType.folkLore;
    } else if (name.contains('sinh thái') || name.contains('ecology')) {
      return MarkerType.ecology;
    } else if (name.contains('sự kiện') ||
        name.contains('lễ hội') ||
        name.contains('event') ||
        name.contains('festival')) {
      return MarkerType.eventAndFestival;
    } else if (name.contains('đặc sản') ||
        name.contains('địa phương') ||
        name.contains('local') ||
        name.contains('specialties')) {
      return MarkerType.localSpecialties;
    } else if (name.contains('ocop')) {
      return MarkerType.ocopProduct;
    } else {
      return MarkerType.buildingDestination;
    }
  }
}
