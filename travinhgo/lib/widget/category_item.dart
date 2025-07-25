import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:travinhgo/screens/introduction/introduction_page.dart';

import '../screens/notification/message_screen.dart';
import '../screens/destination/destination_screen.dart';
import '../screens/event_festival/event_festival_screen.dart';
import '../screens/local_specialty/local_specialty_screen.dart';
import '../screens/ocop_product/ocop_product_screen.dart';
import '../screens/tip/tip_screen.dart';

class CategoryItem extends StatelessWidget {
  final String iconName;
  final Color color;
  final String title;
  final int index;

  const CategoryItem({
    super.key,
    required this.iconName,
    this.color = Colors.transparent,
    required this.title,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> screen = const [
      IntroductionPage(),
      DestinationScreen(),
      LocalSpecialtyScreen(),
      EventFestivalScreen(),
      OcopProductScreen(),
      MessageScreen(),
      TipScreen()
    ];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen[index]),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.sp),
            ),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Image.asset(
                "assets/images/home/$iconName.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            width: 18.w,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
