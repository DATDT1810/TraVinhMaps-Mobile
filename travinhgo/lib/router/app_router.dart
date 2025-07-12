import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/screens/notification/message_screen.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/screens/auth/login_screen.dart';
import 'package:travinhgo/screens/auth/otp_verification_screen.dart';
import 'package:travinhgo/screens/nav_bar_screen.dart';
import 'package:travinhgo/screens/profile/profile_screen.dart';
import 'package:travinhgo/screens/splash/splash_screen.dart';
import 'package:travinhgo/utils/router_logger.dart';

import '../main.dart';
import '../screens/destination/destination_detail_screen.dart';
import '../screens/event_festival/event_fesftival_detail_screen.dart';
import '../screens/favorite/favorite_screen.dart';
import '../screens/feedback/feedback_form_screen.dart';
import '../screens/itinerary_plan/itinerary_plan_screen.dart';
import '../screens/local_specialty/local_specialty_detail_screen.dart';
import '../screens/ocop_product/ocop_product_detail_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/home/home_screen.dart';
import '../widget/auth_required_screen.dart';
import '../main.dart'; // Import to access the global navigatorKey and hasShownSplashScreen

// Specialized observer to monitor navigation during Google Sign-In
class GoogleSignInNavigationObserver extends NavigatorObserver {
  final AuthProvider authProvider;

  GoogleSignInNavigationObserver(this.authProvider);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (authProvider.isGoogleSignInInProgress) {
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: Navigation detected during Google sign-in");
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: Route: ${route.settings.name}, Previous: ${previousRoute?.settings.name}");

      // Log the current route location for debugging
      if (route.settings.name != null &&
          !route.settings.name!.contains('login')) {
        debugPrint(
            "⚠️ GOOGLE_SIGNIN_GUARD: Navigation away from login detected during Google sign-in!");
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (authProvider.isGoogleSignInInProgress) {
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: Pop navigation detected during Google sign-in");
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: Popped: ${route.settings.name}, To: ${previousRoute?.settings.name}");
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (authProvider.isGoogleSignInInProgress) {
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: Route replacement during Google sign-in");
      debugPrint(
          "🔒 GOOGLE_SIGNIN_GUARD: New: ${newRoute?.settings.name}, Old: ${oldRoute?.settings.name}");
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (authProvider.isGoogleSignInInProgress) {
      debugPrint("🔒 GOOGLE_SIGNIN_GUARD: Route removal during Google sign-in");
      debugPrint("🔒 GOOGLE_SIGNIN_GUARD: Removed: ${route.settings.name}");
    }
  }
}

// Custom listenable wrapper that prevents notifications during Google sign-in
class AuthProviderRouterListenable extends ChangeNotifier {
  final AuthProvider _authProvider;

  AuthProviderRouterListenable(this._authProvider) {
    _authProvider.addListener(_onAuthProviderChanged);
  }

  void _onAuthProviderChanged() {
    // CRITICAL FIX: Don't notify router during Google sign-in to prevent navigation
    if (_authProvider.isGoogleSignInInProgress) {
      debugPrint(
          "Log_Auth_flow: ROUTER_LISTENABLE - 🚫 Blocking router refresh during Google sign-in");
      return;
    }

    debugPrint("Log_Auth_flow: ROUTER_LISTENABLE - Allowing router refresh");
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthProviderChanged);
    super.dispose();
  }
}

class AppRouter {
  final AuthProvider authProvider;
  late final AuthProviderRouterListenable _routerListenable;

  // Track the path user was trying to access before being redirected to login
  String? _redirectPath;

  // Add a flag to prevent router loops
  bool _isHandlingRedirect = false;

  AppRouter(this.authProvider) {
    _routerListenable = AuthProviderRouterListenable(authProvider);
  }

  late final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: _routerListenable,
    redirect: _handleRedirect,
    // Use the global navigatorKey from main.dart
    // This helps prevent router from resetting during Google sign-in
    restorationScopeId: 'app',
    routerNeglect: true,
    // CRITICAL FIX: Add configuration to prevent route rebuilding during external auth flows
    requestFocus: false,
    // Prevent automatic focus requests that might trigger navigation
    // ENHANCEMENT: Add specialized observer for Google sign-in
    observers: [
      RouterLogger(
        logTag: 'ROUTER',
        logParameters: true,
      ),
      // Add a specialized observer for Google sign-in navigation
      GoogleSignInNavigationObserver(authProvider),
    ],
    // Add this to prevent route rebuilding when app is backgrounded
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) {
          debugPrint("ROUTER: Showing splash screen for the first time");
          hasShownSplashScreen = true;
          return const SplashScreen();
        },
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          // Check if we have a return path in the query parameters
          final returnTo = state.uri.queryParameters['returnTo'];
          if (returnTo != null && returnTo.isNotEmpty) {
            _redirectPath = returnTo;
            debugPrint("LOGIN ROUTE: Saved return path: $_redirectPath");

            // Make sure we're decoding the return path properly to preserve all information
            try {
              final decodedPath = Uri.decodeComponent(returnTo);
              debugPrint("LOGIN ROUTE: Decoded return path: $decodedPath");
              _redirectPath = decodedPath;
            } catch (e) {
              debugPrint("LOGIN ROUTE: Error decoding return path: $e");
            }
          } else {
            // Get referrer from route history if available to support back navigation
            debugPrint("LOGIN ROUTE: No returnTo parameter provided");
          }
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verifyOtp',
        builder: (context, state) {
          final phoneNumber = state.uri.queryParameters['phoneNumber'];
          final googleEmail = state.uri.queryParameters['googleEmail'];
          debugPrint(
              "ROUTER: Building OTP verification screen with phoneNumber: $phoneNumber, googleEmail: $googleEmail");
          return OtpVerificationScreen(
            phoneNumber: phoneNumber,
            googleEmail: googleEmail,
          );
        },
      ),
      GoRoute(
        path: '/local-specialty-detail/:id',
        name: 'LocalSpecialtyDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LocalSpecialtyDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/event-festival-detail/:id',
        name: 'EventFestivalDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventFesftivalDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/ocop-product-detail/:id',
        name: 'OcopProductDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OcopProductDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/destination-detail/:id',
        name: 'DestinationDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DestinationDetailScreen(
            id: id,
          );
        },
      ),
      GoRoute(
        path: '/notification',
        name: 'Notification',
        builder: (context, state) => MessageScreen(),
      ),
      GoRoute(
        path: '/itinerary-plan',
        name: 'ItineraryPlan',
        builder: (context, state) => ItineraryPlanScreen(),
      ),
      GoRoute(
        path: '/feedback',
        name: 'Feedback',
        builder: (context, state) => FeedbackFormScreen(),
      ),
      GoRoute(
        path: '/tourist-destination-detail/:id',
        name: 'TouristDestinationDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DestinationDetailScreen(
            id: id,
          );
        },
      ),

      // Main app with ShellRoute
      ShellRoute(
        builder: (context, state, child) {
          return ShellNavigator(
            location: state.uri.toString(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const ItineraryPlanScreen(),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const AuthRequiredScreen(
              message: 'Please login to use this feature',
              child: FavoriteScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const AuthRequiredScreen(
              message: 'Please login to use this feature',
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    debugPrint(
        "Log_Auth_flow: ROUTER - Starting redirect handler for location: ${state.matchedLocation}");

    // CRITICAL: Check Google sign-in BEFORE anything else, including the concurrency check
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isGoogleInProgress = authProvider.isGoogleSignInInProgress;
    debugPrint(
        "Log_Auth_flow: ROUTER - Google sign-in in progress: $isGoogleInProgress");

    if (isGoogleInProgress) {
      debugPrint(
          "Log_Auth_flow: ROUTER - 🚫 BLOCKING ALL REDIRECTS - Google Sign-In in progress");
      debugPrint(
          "Log_Auth_flow: ROUTER - Current location: ${state.matchedLocation}");

      // CRITICAL FIX: During Google sign-in, we need to completely prevent any navigation
      // Don't even try to handle any other logic - just block everything
      return null; // Return null to prevent ANY redirect
    }

    // Prevent concurrent redirects
    if (_isHandlingRedirect) {
      debugPrint(
          "Log_Auth_flow: ROUTER - ⚠️ Already handling a redirect, skipping");
      return null;
    }

    _isHandlingRedirect = true;
    debugPrint(
        "Log_Auth_flow: ROUTER - Starting redirect check for ${state.matchedLocation}");

    try {
      // Debug current state
      debugPrint(
          "Log_Auth_flow: ROUTER - Checking redirect for ${state.matchedLocation}");

      // Special case: Redirect from splash to home if already shown
      if (state.matchedLocation == '/') {
        debugPrint(
            "Log_Auth_flow: ROUTER - Path is root '/', checking splash screen state");
        debugPrint(
            "Log_Auth_flow: ROUTER - hasShownSplashScreen = $hasShownSplashScreen");

        if (!hasShownSplashScreen) {
          debugPrint(
              "Log_Auth_flow: ROUTER - First time showing splash, staying on splash");
          hasShownSplashScreen = true;
          return null; // Stay on splash for first time
        } else {
          // CRITICAL FIX: Add one more check here to prevent redirect during Google sign-in
          // Even if we missed it above, catch it here
          if (authProvider.isGoogleSignInInProgress) {
            debugPrint(
                "Log_Auth_flow: ROUTER - 🚫 BLOCKING splash->home redirect - Google Sign-In in progress");
            return null;
          }
          debugPrint(
              "Log_Auth_flow: ROUTER - Splash already shown, redirecting to /home");
          return '/home';
        }
      }

      // Public routes that don't require authentication
      final isPublicRoute = (state.matchedLocation == '/' &&
              !hasShownSplashScreen) || // Only allow splash if not shown yet
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/verify-otp') ||
          state.matchedLocation == '/home' ||
          state.matchedLocation == '/map' ||
          state.matchedLocation.startsWith('/local-specialty-detail/') ||
          state.matchedLocation.startsWith('/event-festival-detail/') ||
          state.matchedLocation.startsWith('/ocop-product-detail/') ||
          state.matchedLocation.startsWith('/tourist-destination-detail/');

      // Protected tab routes that should show the AuthRequiredScreen
      final isProtectedTabRoute = state.matchedLocation == '/events' ||
          state.matchedLocation == '/favorites' ||
          state.matchedLocation == '/profile';

      debugPrint("Log_Auth_flow: ROUTER - Is public route: $isPublicRoute");
      debugPrint(
          "Log_Auth_flow: ROUTER - Is protected tab: $isProtectedTabRoute");

      if (isPublicRoute || isProtectedTabRoute) {
        if (isProtectedTabRoute) {
          debugPrint(
              "Log_Auth_flow: ROUTER - ALLOWING PROTECTED TAB: ${state.matchedLocation} to show AuthRequiredScreen");
        }
        debugPrint(
            "Log_Auth_flow: ROUTER - No redirect needed - allowing to reach destination: ${state.matchedLocation}");
        return null;
      }

      // Only redirect protected routes (not public routes or tab routes)
      final isLoggedIn = authProvider.isAuthenticated;
      debugPrint("Log_Auth_flow: ROUTER - Authentication status: $isLoggedIn");

      if (!isLoggedIn) {
        debugPrint(
            "Log_Auth_flow: ROUTER - User not authenticated, checking route type");

        // If coming from the verify-otp screen but not authenticated
        // (e.g., authentication failed), go to login
        if (state.matchedLocation.startsWith('/verify-otp')) {
          debugPrint(
              "Log_Auth_flow: ROUTER - Redirecting to /login (from verify-otp, not authenticated)");
          return '/login';
        }

        // Check if we're already in the login flow
        if (state.matchedLocation.startsWith('/login')) {
          debugPrint(
              "Log_Auth_flow: ROUTER - Already on login screen, no redirect needed");
          return null;
        }

        // Store the path the user was trying to access (but not for protected tabs)
        if (!isProtectedTabRoute) {
          _redirectPath = state.matchedLocation;
          debugPrint(
              "Log_Auth_flow: ROUTER - User not authenticated. Saving redirect path: $_redirectPath");

          // Make sure we include any query parameters in the saved path
          final fullPath = state.uri.toString();
          if (fullPath != state.matchedLocation) {
            _redirectPath = fullPath;
            debugPrint(
                "Log_Auth_flow: ROUTER - Using full path with query params: $_redirectPath");
          }

          // Redirect to login with returnTo parameter
          final redirectUrl =
              '/login?returnTo=${Uri.encodeComponent(_redirectPath!)}';
          debugPrint("Log_Auth_flow: ROUTER - Redirecting to $redirectUrl");
          return redirectUrl;
        }
      } else {
        debugPrint(
            "Log_Auth_flow: ROUTER - User is authenticated, allowing access");
      }

      // If user is logged in and trying to access login or OTP screens,
      // redirect to home or saved redirect path
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation.startsWith('/verify-otp'))) {
        final redirectTo = _redirectPath ?? '/home';
        debugPrint(
            "Log_Auth_flow: ROUTER - User is already authenticated. Using saved redirect path: $redirectTo");

        // Check if the redirect path is one of our tab routes to ensure correct tab selection
        // This ensures we return to the correct tab in the navigation bar
        if (redirectTo == '/itinerary-plan' ||
            redirectTo == '/favorites' ||
            redirectTo == '/profile' ||
            redirectTo == '/map' ||
            redirectTo == '/home') {
          debugPrint(
              "Log_Auth_flow: ROUTER - Returning to tab route: $redirectTo");
        } else {
          debugPrint(
              "Log_Auth_flow: ROUTER - Returning to non-tab route: $redirectTo");
        }

        _redirectPath = null; // Clear after use
        return redirectTo;
      }

      // No redirect needed
      debugPrint(
          "Log_Auth_flow: ROUTER - No redirect needed - authenticated user at ${state.matchedLocation}");
      return null;
    } finally {
      // Always reset the flag when done
      _isHandlingRedirect = false;
      debugPrint(
          "Log_Auth_flow: ROUTER - Redirect check completed for ${state.matchedLocation}");
    }
  }

  // Clean up the custom listenable when the router is disposed
  void dispose() {
    _routerListenable.dispose();
  }
}
