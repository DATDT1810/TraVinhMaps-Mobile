import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Models/Maps/top_favorite_destination.dart';
import '../../../widget/home_widget/destination/slider_destination_card.dart';

class ImageSliderDestination extends StatelessWidget {
  final List<TopFavoriteDestination> favoriteDestinations;

  const ImageSliderDestination({super.key, required this.favoriteDestinations});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: favoriteDestinations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, index) {
          final destination = favoriteDestinations[index];
          return SliderDestinationCard(
            id: destination.id!,
            title: destination.name!,
            imageUrl: destination.image!,
            averageRating: destination.averageRating,
          );
        },
      ),
    );
  }
}
