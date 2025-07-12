import 'package:travinhgo/Models/review/rating_summary.dart';
import 'package:travinhgo/Models/review/review.dart';

class ReviewListResponse {
  final bool hasReviewed;
  final List<ReviewResponse> reviews;
  final RatingSummary ratingSummary;

  ReviewListResponse({
    required this.hasReviewed,
    required this.reviews,
    required this.ratingSummary,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    return ReviewListResponse(
      hasReviewed: json['hasReviewed'] ?? false,
      reviews: (json['reviews'] as List)
          .map((e) => ReviewResponse.fromJson(e))
          .toList(),
      ratingSummary: RatingSummary.fromJson(json['ratingSummary']),
    );
  }
}
