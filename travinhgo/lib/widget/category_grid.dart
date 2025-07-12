import 'package:flutter/material.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
      colorScheme.errorContainer,
      colorScheme.primaryContainer.withOpacity(0.7),
      colorScheme.secondaryContainer.withOpacity(0.7),
      colorScheme.tertiaryContainer.withOpacity(0.7),
      colorScheme.errorContainer.withOpacity(0.7),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 5,
        children: [
          CategoryItem(
            iconName: "coconut-tree",
            color: categoryColors[0],
            title: AppLocalizations.of(context)!.introduce,
            index: 5,
          ),
          CategoryItem(
            iconName: "plantingtree",
            color: categoryColors[1],
            title: AppLocalizations.of(context)!.ocop,
            index: 4,
          ),
          CategoryItem(
            iconName: "lightbulb",
            color: categoryColors[2],
            title: AppLocalizations.of(context)!.tipTravel,
            index: 0,
          ),
          CategoryItem(
            iconName: "destination",
            color: categoryColors[3],
            title: AppLocalizations.of(context)!.destination,
            index: 1,
          ),
          CategoryItem(
            iconName: "food",
            color: categoryColors[4],
            title: AppLocalizations.of(context)!.localSpecialty,
            index: 2,
          ),
          CategoryItem(
            iconName: "hotel",
            color: categoryColors[5],
            title: AppLocalizations.of(context)!.event,
            index: 3,
          ),
          CategoryItem(
            iconName: "dragon-boat",
            color: categoryColors[6],
            title: AppLocalizations.of(context)!.tipTravel,
            index: 6,
          ),
          CategoryItem(
            iconName: "resource-allocation",
            color: categoryColors[7],
            title: AppLocalizations.of(context)!.utilities,
            index: 0,
          ),
        ],
      ),
    );
  }
}
