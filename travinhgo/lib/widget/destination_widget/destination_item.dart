import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/screens/destination/destination_detail_screen.dart';
import 'package:travinhgo/utils/constants.dart';

import '../../Models/interaction/item_type.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../utils/string_helper.dart';

class DestinationItem extends StatelessWidget {
  final Destination destination;

  const DestinationItem({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);
    final interactionProvider = InteractionProvider.of(context);

    return GestureDetector(
      onTap: () {
        interactionProvider.addInterac(destination.id, ItemType.Destination);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DestinationDetailScreen(
                      id: destination.id,
                    )));
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ]),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 175,
                          height: 190,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              image: DecorationImage(
                                  image: NetworkImage(destination.images[0]),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            favoriteProvider
                                .toggleDestinationFavorite(destination);
                          },
                          child: Icon(
                            favoriteProvider.isExist(destination.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: colorScheme.error,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    StringHelper.toTitleCase(destination.name),
                    maxLines: 2,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Text(
                        destination.avarageRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(width: 5),
                      ...List.generate(5, (index) {
                        double rating = destination.avarageRating;
                        if (index < rating.floor()) {
                          return Icon(Icons.star,
                              color: colorScheme.secondary, size: 15);
                        } else if (index < rating && rating - index >= 0.5) {
                          return Icon(Icons.star_half,
                              color: colorScheme.secondary, size: 15);
                        } else {
                          return Icon(Icons.star_border,
                              color: colorScheme.secondary, size: 15);
                        }
                      }),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Image.network(
                        destinationTypeProvider
                                .getDestinationtypeById(
                                    destination.destinationTypeId)
                                .marker
                                ?.image ??
                            '',
                        width: 25,
                        height: 25,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          destination.address.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
