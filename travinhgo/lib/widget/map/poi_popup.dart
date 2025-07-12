import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:here_sdk/core.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/map_provider.dart';
import 'package:travinhgo/widget/ocop_product_widget/rating_star_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// POI information popup widget
class PoiPopup extends StatelessWidget {
  const PoiPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    if (!mapProvider.showPoiPopup || mapProvider.lastPoiCoordinates == null) {
      return const SizedBox.shrink();
    }

    final metadata = mapProvider.lastPoiMetadata;
    final String name = mapProvider.lastPoiName ??
        AppLocalizations.of(context)!.unknownLocation;

    // Unified handling for rating
    final double rating = (metadata?.getDouble('place_rating') ??
        double.tryParse(metadata?.getString('product_rating') ?? '0.0') ??
        0.0);

    // Unified handling for images
    final imagesString = metadata?.getString('place_images') ??
        metadata?.getString('product_images');
    final List<String> images = imagesString != null && imagesString.isNotEmpty
        ? imagesString.split(',')
        : [];
    final String address = metadata?.getString('place_address') ??
        '${mapProvider.lastPoiCoordinates!.latitude.toStringAsFixed(5)}, ${mapProvider.lastPoiCoordinates!.longitude.toStringAsFixed(5)}';

    final bool isOcop = metadata?.getString("is_ocop_product") == "true";
    final String? ocopProductId = metadata?.getString("product_id");
    final String? destinationId = metadata?.getString("destination_id");
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final String category =
        metadata?.getString("place_category") ?? l10n.unknownLocation;
    final String coordinates =
        '${mapProvider.lastPoiCoordinates!.latitude.toStringAsFixed(5)}, ${mapProvider.lastPoiCoordinates!.longitude.toStringAsFixed(5)}';

    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 4),
                                    if (isOcop)
                                      RatingStarWidget(rating.round())
                                    else
                                      // Generic star rating for non-OCOP
                                      ...List.generate(5, (index) {
                                        if (rating >= index + 1) {
                                          return Icon(Icons.star,
                                              color: colorScheme.secondary,
                                              size: 16);
                                        } else if (rating >= index + 0.5) {
                                          return Icon(Icons.star_half,
                                              color: colorScheme.secondary,
                                              size: 16);
                                        } else {
                                          return Icon(Icons.star_border,
                                              color: colorScheme.secondary,
                                              size: 16);
                                        }
                                      }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Space for close button
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildActionButton(context, Icons.directions,
                            AppLocalizations.of(context)!.direct, true, () {
                          if (mapProvider.lastPoiCoordinates != null) {
                            mapProvider.startRouting(
                              mapProvider.lastPoiCoordinates!,
                              name,
                            );
                            mapProvider.closePoiPopup();
                          }
                        }),
                        const SizedBox(width: 8),
                        _buildActionButton(context, Icons.play_arrow,
                            AppLocalizations.of(context)!.start, false, () {
                          // Could be used for turn-by-turn navigation start
                        }),
                        if ((isOcop && ocopProductId != null) ||
                            (destinationId != null)) ...[
                          const SizedBox(width: 8),
                          _buildActionButton(context, Icons.info_outline,
                              AppLocalizations.of(context)!.detail, false, () {
                            if (isOcop && ocopProductId != null) {
                              GoRouter.of(context)
                                  .push('/ocop-product-detail/$ocopProductId');
                              mapProvider.closePoiPopup();
                            } else if (destinationId != null) {
                              GoRouter.of(context)
                                  .push('/destination-detail/$destinationId');
                              mapProvider.closePoiPopup();
                            }
                          }),
                        ],
                        const SizedBox(width: 8),
                        _buildActionButton(context, Icons.share,
                            AppLocalizations.of(context)!.share, false, () {
                          final textToShare = AppLocalizations.of(context)!
                              .shareText(name, address);
                          Share.share(textToShare);
                        }),
                      ],
                    ),
                  ),

                  // Image Gallery
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 160,
                                  height: 120,
                                  color: colorScheme.surfaceVariant,
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 160,
                                  height: 120,
                                  color: colorScheme.surfaceVariant,
                                  child: Icon(Icons.error,
                                      color: colorScheme.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _buildInfoRow(context, Icons.location_on_outlined, address),
                  _buildInfoRow(context, Icons.category_outlined, category),
                  _buildInfoRow(context, Icons.map_outlined, coordinates),
                ],
              ),
            ),
          ),
          // Close Button
          Positioned(
            top: 11,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.scrim,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.close, color: colorScheme.onInverseSurface),
                iconSize: 20,
                onPressed: () => mapProvider.closePoiPopup(),
                splashRadius: 20,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      bool isPrimary, VoidCallback onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isPrimary ? colorScheme.primary : colorScheme.secondaryContainer;
    final foregroundColor =
        isPrimary ? colorScheme.onPrimary : colorScheme.onSecondaryContainer;

    return ActionChip(
      avatar: Icon(icon, color: foregroundColor, size: 20),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      labelStyle:
          TextStyle(color: foregroundColor, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
