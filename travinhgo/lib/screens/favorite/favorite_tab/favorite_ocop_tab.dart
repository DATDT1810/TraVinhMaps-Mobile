import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../providers/favorite_provider.dart';
import '../../../widget/ocop_product_widget/ocop_product_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteOcopTab extends StatelessWidget {
  const FavoriteOcopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = FavoriteProvider.of(context);
    final ocops = favoriteProvider.ocopProductList;

    if (ocops.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noFavoriteOcop),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(8.0), // padding ở đây
      itemCount: ocops.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        return OcopProductItem(
          ocopProduct: ocops[index],
        );
      },
    );
  }
}
