import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../models/maps/top_favorite_destination.dart';
import '../../providers/map_provider.dart';

/// Favorite destinations carousel slider
class FavoriteDestinationsSlider extends StatefulWidget {
  const FavoriteDestinationsSlider({Key? key}) : super(key: key);

  @override
  State<FavoriteDestinationsSlider> createState() =>
      _FavoriteDestinationsSliderState();
}

class _FavoriteDestinationsSliderState
    extends State<FavoriteDestinationsSlider> {
  // PageController for the destination carousel
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called when the destination carousel is swiped
  void _onDestinationPageChanged(int index, MapProvider provider) {
    provider.updateCurrentDestination(index);
  }

  /// Called when a POI is selected to show its details
  void _showPOIDetails(
      TopFavoriteDestination destination, MapProvider provider) {
    // Move map to the selected destination
    if (destination.id != null) {
      provider.moveToDestination(destination.id!);
    }
  }

  /// Builds the destination image or a placeholder
  Widget _buildDestinationImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(Icons.image,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  /// Builds the rating display for a destination
  Widget _buildDestinationRating(double rating) {
    return Row(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        ...List.generate(
          5,
          (index) => Icon(
            index < rating.floor()
                ? Icons.star
                : (index == rating.floor() && rating % 1 > 0)
                    ? Icons.star_half
                    : Icons.star_border,
            color: Theme.of(context).colorScheme.secondary.withAlpha(230),
            size: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        if (provider.topDestinations.isEmpty) return SizedBox.shrink();

        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 0,
          right: 0,
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: provider.topDestinations.length,
                  onPageChanged: (index) =>
                      _onDestinationPageChanged(index, provider),
                  itemBuilder: (context, index) {
                    final destination = provider.topDestinations[index];
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity:
                          provider.currentDestinationIndex == index ? 1.0 : 0.7,
                      child: GestureDetector(
                        onTap: () => _showPOIDetails(destination, provider),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withAlpha(250),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                child: _buildDestinationImage(
                                    destination.image, 80, double.infinity),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        destination.name ??
                                            AppLocalizations.of(context)!
                                                .unnamedLocation,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 3),
                                      _buildDestinationRating(
                                          destination.averageRating ?? 0),
                                      SizedBox(height: 0),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Html(
                                            data: destination.description ??
                                                AppLocalizations.of(context)!
                                                    .noDescriptionAvailable,
                                            style: {
                                              "body": Style(
                                                fontSize: FontSize(11),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withAlpha(230),
                                                margin: Margins.zero,
                                                padding: HtmlPaddings.zero,
                                              ),
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
