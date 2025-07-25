import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/providers/favorite_provider.dart';

import '../../utils/string_helper.dart';
import '../../Models/interaction/item_type.dart';
import '../../providers/interaction_provider.dart';

class LocalSpecialtyItem extends StatelessWidget {
  final LocalSpecialties localSpecialty;
  final bool isAllowFavorite;

  const LocalSpecialtyItem({super.key, required this.localSpecialty, required this.isAllowFavorite});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final interactionProvider = InteractionProvider.of(context);

    return GestureDetector(
      onTap: () {
        interactionProvider.addInterac(
            localSpecialty.id, ItemType.LocalSpecialties);
        context.pushNamed(
          'LocalSpecialtyDetail',
          pathParameters: {'id': localSpecialty.id},
        );
      },
      child: Card(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with Favorite Icon
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.sp),
                  topRight: Radius.circular(12.sp),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      localSpecialty.images.first,
                      fit: BoxFit.cover,
                    ),
                    if (isAllowFavorite) Positioned(
                      top: 1.h,
                      right: 2.w,
                      child: GestureDetector(
                        onTap: () {
                          favoriteProvider
                              .toggleLocalSpecialtiesFavorite(localSpecialty);
                        },
                        child: Icon(
                          favoriteProvider.isExist(localSpecialty.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Theme.of(context).colorScheme.error,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Name + Icon
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12.sp,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.ramen_dining,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 15.sp,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 5.h, // Fixed height for the title
                            child: Text(
                              StringHelper.toTitleCase(localSpecialty.foodName),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
