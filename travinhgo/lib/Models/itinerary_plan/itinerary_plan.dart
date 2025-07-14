import '../destination/destination.dart';

class ItineraryPlan {
  final String id;
  final String name;
  final String? duration;
  final List<String> locations;
  final String? estimatedCost;
  final List<Destination> touristDestinations;

  ItineraryPlan(
      {required this.id,
      required this.name,
      this.duration,
      required this.locations,
      this.estimatedCost,
      required this.touristDestinations});

  factory ItineraryPlan.fromJson(Map<String, dynamic> json) {
    return ItineraryPlan(
      id: json['id'],
      name: json['name'],
      duration: json['duration'],
      locations: List<String>.from(json['locations']),
      estimatedCost: json['estimatedCost'],
      touristDestinations: (json['touristDestinations'] as List)
          .map((e) => Destination.fromJson(e))
          .toList(),
    );
  }
}
