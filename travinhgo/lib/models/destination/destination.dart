class Destination {
  final String id;
  final String name;
  final double avarageRating;
  final String? description;
  final String? address;
  final Location location;
  final List<String> images;
  final HistoryStory? historyStory;
  final DateTime? updateAt;
  final String destinationTypeId;
  final OpeningHours? openingHours;
  final String? capacity;
  final Contact? contact;
  final String tagId;
  final String? ticket;
  int? favoriteCount;
  final bool status;

  Destination(
      {required this.id,
      required this.name,
      required this.avarageRating,
      this.description,
      this.address,
      required this.location,
      required this.images,
      this.historyStory,
      this.updateAt,
      required this.destinationTypeId,
      this.openingHours,
      this.capacity,
      this.contact,
      required this.tagId,
      this.ticket,
      this.favoriteCount,
      required this.status});

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      avarageRating: (json['avarageRating'] as num).toDouble(),
      description: json['description'],
      address: json['address'],
      location: Location.fromJson(json['location']),
      images: List<String>.from(json['images']),
      historyStory: json['historyStory'] != null
          ? HistoryStory.fromJson(json['historyStory'])
          : null,
      updateAt:
          json['updateAt'] != null ? DateTime.parse(json['updateAt']) : null,
      destinationTypeId: json['destinationTypeId'],
      openingHours: json['openingHours'] != null
          ? OpeningHours.fromJson(json['openingHours'])
          : null,
      capacity: json['capacity'],
      contact:
          json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      tagId: json['tagId'],
      ticket: json['ticket'],
      favoriteCount: json['favoriteCount'],
      status: json['status'],
    );
  }
}

class Location {
  final String? type;
  final List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates:
          List<double>.from(json['coordinates'].map((e) => e.toDouble())),
    );
  }
}

class HistoryStory {
  final String? content;
  final List<String>? images;

  HistoryStory({this.content, this.images});

  factory HistoryStory.fromJson(Map<String, dynamic> json) {
    return HistoryStory(
      content: json['content'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }
}

class OpeningHours {
  final String? openTime;
  final String? closeTime;

  OpeningHours({this.openTime, this.closeTime});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openTime: json['openTime'],
      closeTime: json['closeTime'],
    );
  }
}

class Contact {
  final String? phone;
  final String? email;
  final String? website;

  Contact({this.phone, this.email, this.website});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
    );
  }
}
