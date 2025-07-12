import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/sampledata/samplelist.dart';
import 'package:travinhgo/widget/category_grid.dart';
import 'package:travinhgo/widget/category_item.dart';
import 'package:travinhgo/widget/home_header.dart';
import 'package:travinhgo/widget/image_slider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../Models/Maps/top_favorite_destination.dart';
import '../../Models/event_festival/event_and_festival.dart';
import '../../Models/ocop/ocop_product.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/home_service.dart';
import '../../utils/constants.dart';
import '../../widget/home_widget/destination/image_slider_destination.dart';
import '../../widget/home_widget/event_festival/image_slider_event.dart';
import '../../widget/home_widget/ocop/image_slider_ocop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TopFavoriteDestination> _favoriteDestinations = [];
  List<EventAndFestival> _topEvents = [];
  List<OcopProduct> _ocopProducts = [];
  bool _handledInitialMessage = false;

  @override
  void initState() {
    super.initState();
    pushNotificationService.firebaseInit(context);

    // fetchdata
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await HomeService().getHomePageData();
    if (data != null) {
      setState(() {
        _favoriteDestinations = data.favoriteDestinations;
        _topEvents = data.topEvents;
        _ocopProducts = data.ocopProducts;
      });
    } else {
      // Xử lý khi data null, ví dụ:
      setState(() {
        _favoriteDestinations = [];
        _topEvents = [];
        _ocopProducts = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color to match our header
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent status bar
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark, // light status bar icons
    ));
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final colorScheme = Theme.of(context).colorScheme;

    // No longer using ProtectedScreen - allowing access to all users
    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      body: Container(
        color: colorScheme.primary,
        child: Column(
          children: [
            // Empty space for status bar with green background
            SizedBox(height: statusBarHeight),
            // Header already has green background
            const HomeHeader(),
            // Main content with white background
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: SafeArea(
                  top: false, // Header already accounts for top padding
                  bottom: true, // Keep bottom safe area
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Ensure the content has enough space to scroll
                        minHeight: screenHeight -
                            statusBarHeight -
                            MediaQuery.of(context).padding.bottom -
                            80, // Account for header
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: Column(
                          children: [
                            // Welcome message
                            const SizedBox(height: 15),
                            // Search bar
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                        color: colorScheme.shadow
                                            .withOpacity(0.15),
                                        blurRadius: 5),
                                  ],
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .searchHere,
                                    hintStyle: TextStyle(
                                        fontSize: 20,
                                        color: colorScheme.onSurfaceVariant),
                                    border: InputBorder.none,
                                    icon: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Image.asset(
                                        "assets/images/navigations/search.png",
                                        scale: 25,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    print("địa chỉ được nhập là " + value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Image slider
                            ImageSlider(imageList: imageListHome),
                            // Categories grid - now using the CategoryGrid widget
                            const CategoryGrid(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Activities",
                                      style: TextStyle(
                                          color: kprimaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: ImageSliderEvent(
                                      topEvents: _topEvents,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Tourist attraction",
                                      style: TextStyle(
                                          color: kprimaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: ImageSliderDestination(
                                      favoriteDestinations:
                                          _favoriteDestinations,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Featured ocop products",
                                      style: TextStyle(
                                          color: kprimaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: ImageSliderOcop(
                                      ocopProducts: _ocopProducts,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
