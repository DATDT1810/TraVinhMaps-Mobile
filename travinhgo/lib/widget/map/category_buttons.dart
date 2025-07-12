import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/map_provider.dart';
import '../../utils/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Widget for displaying category filter buttons on the map
class CategoryButtons extends StatelessWidget {
  const CategoryButtons({Key? key}) : super(key: key);

  String _getLocalizedCategoryName(BuildContext context, String categoryName) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryName) {
      case "All":
        return l10n.all;
      case "OCOP":
        return l10n.ocop;
      case "Hotels":
        return l10n.categoryHotels;
      case "Restaurants":
        return l10n.categoryRestaurants;
      case "Cafes":
        return l10n.categoryCafes;
      case "Fuel":
        return l10n.categoryFuel;
      case "ATMs":
        return l10n.categoryAtms;
      case "Banks":
        return l10n.categoryBanks;
      case "Schools":
        return l10n.categorySchools;
      case "Hospitals":
        return l10n.categoryHospitals;
      case "Police":
        return l10n.categoryPolice;
      case "Bus Stops":
        return l10n.categoryBusStops;
      case "Stores":
        return l10n.categoryStores;
      default:
        return categoryName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, child) {
        // Get selected category index and category list
        final selectedIndex = provider.selectedCategoryIndex;
        final categoryList = provider.categories;

        // Calculate required space for system status bar
        final statusBarHeight = MediaQuery.of(context).padding.top;

        return Positioned(
          top: statusBarHeight + 56,
          left: 0,
          right: 0,
          child: Container(
            height: 44,
            margin: const EdgeInsets.only(top: 14),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                final isSelected =
                    selectedIndex == index && provider.isCategoryActive;
                final localizedName =
                    _getLocalizedCategoryName(context, categoryList[index]);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      localizedName,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Image.asset(
                      provider.getCategoryIconForState(index, isSelected),
                      width: 20,
                      height: 20,
                      color: isSelected && provider.isCategoryTintable(index)
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    onSelected: (selected) {
                      provider.updateSelectedCategory(index);
                    },
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withAlpha(128),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
