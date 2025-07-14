import 'package:flutter/cupertino.dart';

import '../../../Models/ocop/ocop_product.dart';
import '../../../widget/home_widget/ocop/slider_ocop_card.dart';

class ImageSliderOcop extends StatelessWidget {
  final List<OcopProduct> ocopProducts;
  const ImageSliderOcop({super.key, required this.ocopProducts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 245,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ocopProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final ocop = ocopProducts[index];
          return SliderOcopCard(
            id: ocop.id,
            title: ocop.productName,
            imageUrl: ocop.productImage[0],
            companyName: ocop.company.name,
          );
        },
      ),
    );
  }
}
