import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/providers/card_provider.dart';
import 'package:travinhgo/providers/map_provider.dart';
import 'package:travinhgo/providers/notification_provider.dart';
import 'package:travinhgo/providers/ocop_type_provider.dart';
import 'package:travinhgo/providers/setting_provider.dart';
import 'package:travinhgo/providers/user_provider.dart';
import 'package:travinhgo/router/app_router.dart';
import 'package:travinhgo/providers/destination_type_provider.dart';
import 'package:travinhgo/providers/marker_provider.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/services/push_notification_service.dart';
import 'package:travinhgo/utils/env_config.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

// Import HERE SDK directly in main.dart
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'firebase_options.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final PushNotificationService pushNotificationService =
    PushNotificationService();

// Global flag to track if splash screen has been shown
bool hasShownSplashScreen = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.initialize();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize HERE SDK before any map-related component is created
  try {
    developer.log('Initializing HERE SDK...', name: 'main');

    // Wait for HERE SDK initialization to complete
    await _initializeHERESDK();

    await pushNotificationService.initLocalNotification();

    developer.log('HERE SDK initialized successfully', name: 'main');
  } catch (e) {
    developer.log('Exception during HERE SDK initialization',
        name: 'main', error: e.toString());
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app after HERE SDK is initialized
  runApp(MyApp());
}

Future<void> _initializeHERESDK() async {
  // Initialize the HERE SDK library context
  SdkContext.init(IsolateOrigin.main);

  // Add a small delay to ensure FFI functions are properly registered
  await Future.delayed(const Duration(milliseconds: 100));

  final accessKeyId = EnvConfig.hereApiKey;
  final accessKeySecret = EnvConfig.hereApiSecret;

  if (accessKeyId.isEmpty || accessKeySecret.isEmpty) {
    throw Exception("HERE API credentials are missing");
  }

  // Create authentication and initialize engine
  final authMode =
      AuthenticationMode.withKeySecret(accessKeyId, accessKeySecret);
  final options = SDKOptions.withAuthenticationMode(authMode);

  try {
    await SDKNativeEngine.makeSharedInstance(options);
    developer.log('HERE SDK engine initialized successfully', name: 'main');
  } on InstantiationException catch (e) {
    developer.log('Failed to initialize HERE SDK engine',
        name: 'main', error: e.toString());
    throw Exception("Failed to initialize the HERE SDK: ${e.error.name}");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Create providers and router once
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _appRouter = AppRouter(_authProvider);
  }

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _authProvider),
          ChangeNotifierProvider(create: (_) => CardProvider()),
          ChangeNotifierProvider(create: (_) => SettingProvider()),
          ChangeNotifierProvider(create: (_) => MarkerProvider()),
          ChangeNotifierProvider(create: (_) => MapProvider()),
          ChangeNotifierProvider(create: (_) => DestinationTypeProvider()),
          ChangeNotifierProvider(create: (_) => TagProvider()),
          ChangeNotifierProvider(create: (_) => OcopTypeProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: MaterialApp.router(
          title: "TraVinhGo",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF158247)),
            useMaterial3: true,
            textTheme: GoogleFonts.montserratTextTheme(),
          ),
          routerConfig: _appRouter.router,
          restorationScopeId: 'app_scope',
        ),
      );
}
