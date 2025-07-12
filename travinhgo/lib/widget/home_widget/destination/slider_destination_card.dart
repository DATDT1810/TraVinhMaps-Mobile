import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/constants.dart';
import '../../../utils/string_helper.dart';

class SliderDestinationCard extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final double? averageRating;

  const SliderDestinationCard(
      {super.key,
      required this.id,
      required this.imageUrl,
      this.averageRating,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'DestinationDetail',
          pathParameters: {'id': id},
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        elevation: 4,
        color: kbackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 40),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    StringHelper.toTitleCase(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        averageRating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      ...List.generate(5, (index) {
                        double rating = averageRating!;
                        if (index < rating.floor()) {
                          return Icon(Icons.star,
                              color: CupertinoColors.systemYellow, size: 14);
                        } else if (index < rating && rating - index >= 0.5) {
                          return Icon(Icons.star_half,
                              color: CupertinoColors.systemYellow, size: 14);
                        } else {
                          return Icon(Icons.star_border,
                              color: CupertinoColors.systemYellow, size: 14);
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
