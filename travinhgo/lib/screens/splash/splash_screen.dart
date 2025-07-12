import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/models/marker/marker.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/providers/marker_provider.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/providers/map_provider.dart';
import 'package:travinhgo/utils/constants.dart';
import 'dart:developer' as developer;

import '../../main.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/ocop_type_provider.dart';
import '../../services/push_notification_service.dart';
import '../../providers/ocop_product_provider.dart';
import '../../providers/destination_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Minimum splash screen duration
  static const splashDuration = Duration(seconds: 2);

  // Maximum time to wait for data loading before moving on
  static const maxLoadingTime = Duration(seconds: 5);

  bool _isDataLoaded = false;
  bool _isSplashDone = false;
  Timer? _maxLoadingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashTimer();
      _startDataLoading();
      _startMaxLoadingTimer();
    });
  }

  @override
  void dispose() {
    _maxLoadingTimer?.cancel();
    super.dispose();
  }

  void _startSplashTimer() {
    // Minimum time to show splash screen
    Timer(splashDuration, () {
      if (mounted) {
        setState(() => _isSplashDone = true);
        _checkNavigationConditions();
      }
    });
  }

  void _startMaxLoadingTimer() {
    // Maximum time to wait for data loading
    _maxLoadingTimer = Timer(maxLoadingTime, () {
      if (mounted && !_isDataLoaded) {
        debugPrint(
            'Data loading timeout reached. Moving to home screen anyway.');
        setState(() => _isDataLoaded = true);
        _checkNavigationConditions();
      }
    });
  }

  void _startDataLoading() {
    _loadData().then((_) async {
      // Initialize FCM
      await pushNotificationService.requestNotificationPermission();
      await pushNotificationService.subscribeToGeneralTopic();
      pushNotificationService.firebaseInit(context);

      if (mounted) {
        setState(() => _isDataLoaded = true);
        _checkNavigationConditions();
      }
    }).catchError((error) {
      debugPrint('Error loading data: $error');
      // 🔔 Initialize FCM even if data loading fails
      // pushNotificationService.requestNotificationPermisstion();
      // pushNotificationService.subscribeToGeneralTopic();
      // pushNotificationService.firebaseInit(context);
      if (mounted) {
        setState(() => _isDataLoaded =
            true); // Consider data loading "done" even with error
        _checkNavigationConditions();
      }
    });
  }

  void _checkNavigationConditions() {
    // Navigate when both splash animation is done and data is loaded (or timed out)
    if (_isSplashDone && _isDataLoaded && mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                fontFamily: 'Aclonica',
              ),
              child: AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'TraVinhGo',
                    speed: const Duration(microseconds: 200),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 500),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isDataLoaded)
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
                strokeWidth: 2,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final markerProvider =
          Provider.of<MarkerProvider>(context, listen: false);
      final destinationTypeProvider =
          Provider.of<DestinationTypeProvider>(context, listen: false);
      final tagProvider = Provider.of<TagProvider>(context, listen: false);
      final ocopTypeProvider =
          Provider.of<OcopTypeProvider>(context, listen: false);
      final favoriteProvider =
          Provider.of<FavoriteProvider>(context, listen: false);
      final ocopProductProvider =
          Provider.of<OcopProductProvider>(context, listen: false);
      final destinationProvider =
          Provider.of<DestinationProvider>(context, listen: false);
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      final interactionProvider =
          Provider.of<InteractionProvider>(context, listen: false);
      final interactionLogProvider =
          Provider.of<InteractionLogProvider>(context, listen: false);

      // Start all loading operations in parallel
      developer.log(
          'data_ocop: Starting to load all data including OCOP products',
          name: 'SplashScreen');
      final markersFuture = markerProvider.fetchMarkers();
      final destinationTypesFuture =
          destinationTypeProvider.fetchDestinationType();
      final tagsFuture = tagProvider.fetchDestinationType();
      final ocopTypeFuture = ocopTypeProvider.fetchOcopType();
      final favoriteFuture = favoriteProvider.fetchFavorites();
      final ocopProductsFuture = ocopProductProvider.fetchOcopProducts();

      // Wait for all data to load
      await Future.wait([
        markersFuture,
        destinationTypesFuture,
        tagsFuture,
        ocopTypeFuture,
        favoriteFuture,
        ocopProductsFuture,
      ]);

      // Initialize map sub-providers
      developer.log('data_ocop: Initializing map sub-providers',
          name: 'SplashScreen');
      mapProvider.initializeMapSubProviders(
          ocopProductProvider, destinationProvider);

      debugPrint(
          '______________________________________________________________');
      for (var fav in favoriteProvider.favorites) {
        debugPrint(fav.itemId.toString());
      }
      debugPrint(
          '______________________________________________________________');

      // Associate markers with destination types
      final markers = markerProvider.markers;
      for (var destinationType in destinationTypeProvider.destinationTypes) {
        final matchedMarker = markers.firstWhere(
          (m) => m.id == destinationType.markerId,
          orElse: () => Marker(id: '', name: 'Unknown', image: ''),
        );
        destinationType.marker =
            matchedMarker.id.isEmpty ? null : matchedMarker;
      }

      // Preload marker images for better performance
      // Don't wait for all images - do up to 5 seconds then stop
      final futures = <Future>[];
      for (final marker in markers) {
        if (marker.image.isNotEmpty) {
          futures.add(precacheImage(NetworkImage(marker.image), context));
        }
      }

      // Use timeout to ensure images don't take too long
      await Future.wait(futures).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Image preloading timed out, continuing anyway');
          return [];
        },
      );

      developer.log('data_ocop: All data loaded successfully in splash screen',
          name: 'SplashScreen');
    } catch (e) {
      developer.log('data_ocop: Error during data loading: $e',
          name: 'SplashScreen');
      // We still return normally to allow navigation to continue
    }
  }
}
