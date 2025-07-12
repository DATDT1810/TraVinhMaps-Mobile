class RatingSummary {
  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  final double oneStarPercent;
  final double twoStarPercent;
  final double threeStarPercent;
  final double fourStarPercent;
  final double fiveStarPercent;

  RatingSummary({
    required this.oneStar,
    required this.twoStar,
    required this.threeStar,
    required this.fourStar,
    required this.fiveStar,
    required this.oneStarPercent,
    required this.twoStarPercent,
    required this.threeStarPercent,
    required this.fourStarPercent,
    required this.fiveStarPercent,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      oneStar: json['oneStar'] ?? 0,
      twoStar: json['twoStar'] ?? 0,
      threeStar: json['threeStar'] ?? 0,
      fourStar: json['fourStar'] ?? 0,
      fiveStar: json['fiveStar'] ?? 0,
      oneStarPercent: (json['oneStarPercent'] ?? 0).toDouble(),
      twoStarPercent: (json['twoStarPercent'] ?? 0).toDouble(),
      threeStarPercent: (json['threeStarPercent'] ?? 0).toDouble(),
      fourStarPercent: (json['fourStarPercent'] ?? 0).toDouble(),
      fiveStarPercent: (json['fiveStarPercent'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oneStar': oneStar,
      'twoStar': twoStar,
      'threeStar': threeStar,
      'fourStar': fourStar,
      'fiveStar': fiveStar,
      'oneStarPercent': oneStarPercent,
      'twoStarPercent': twoStarPercent,
      'threeStarPercent': threeStarPercent,
      'fourStarPercent': fourStarPercent,
      'fiveStarPercent': fiveStarPercent,
    };
  }
}
