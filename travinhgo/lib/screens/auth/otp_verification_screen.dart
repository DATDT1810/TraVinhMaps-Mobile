import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travinhgo/providers/auth_provider.dart';
import 'package:travinhgo/services/auth_service.dart';
import 'package:travinhgo/widget/status_dialog.dart';
import 'package:travinhgo/widget/success_dialog.dart';
import 'package:travinhgo/router/app_router.dart'
    hide Scaffold; // Import to access redirect path logic
import 'package:travinhgo/utils/constants.dart'; // Fix import path
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? googleEmail;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.googleEmail,
  });

  @override
  // ignore: no_logic_in_create_state
  State<OtpVerificationScreen> createState() {
    debugPrint(
        "Log_Auth_flow: OTP - Creating OTP verification screen state with phoneNumber: $phoneNumber, googleEmail: $googleEmail");
    return _OtpVerificationScreenState();
  }
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  Timer? _resendTimer;
  int _timeLeft = 300; // 5 minutes in seconds
  String? _otpError;
  bool _otpSubmitted = false; // Track if OTP has been submitted

  @override
  void initState() {
    super.initState();
    debugPrint(
        "Log_Auth_flow: OTP - Screen initialized with phoneNumber: ${widget.phoneNumber}, googleEmail: ${widget.googleEmail}");

    // Start timer immediately
    _startResendTimer();

    // Move ALL context access to post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Now it's safe to access context
      debugPrint(
          "Log_Auth_flow: OTP - Current route: ${ModalRoute.of(context)?.settings.name ?? 'unknown'}");

      // Check if Google sign-in is in progress
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isGoogleInProgress = authProvider.isGoogleSignInInProgress;
      debugPrint(
          "Log_Auth_flow: OTP - Post-frame callback, Google sign-in in progress: $isGoogleInProgress");

      try {
        final router = GoRouter.of(context);
        final currentLocation =
            router.routerDelegate.currentConfiguration.uri.toString();
        debugPrint(
            "Log_Auth_flow: OTP - Current route from GoRouter: $currentLocation");
      } catch (e) {
        debugPrint("Log_Auth_flow: OTP - Error getting current route: $e");
      }

      // Show message popup
      _showMessageSentPopup();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _showMessageSentPopup() {
    // Check if widget is still mounted before showing dialog
    if (!mounted) {
      debugPrint("OTP: Widget not mounted, skipping message popup");
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final bool isGoogleAuth = widget.googleEmail != null;
      final String recipient =
          isGoogleAuth ? widget.googleEmail! : widget.phoneNumber ?? '';

      debugPrint(
          "OTP: Showing message sent popup for ${isGoogleAuth ? 'email' : 'phone'}: $recipient");

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 80.w,
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green icon container
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isGoogleAuth
                        ? Icons.email_outlined
                        : Icons.message_outlined,
                    color: colorScheme.onPrimary,
                    size: 8.w,
                  ),
                ),
                SizedBox(height: 3.h),

                // Title
                Text(
                  isGoogleAuth
                      ? AppLocalizations.of(context)!.checkYourEmail
                      : AppLocalizations.of(context)!.checkYourMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),

                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Column(
                    children: [
                      Text(
                        isGoogleAuth
                            ? AppLocalizations.of(context)!.otpSentTo
                            : AppLocalizations.of(context)!
                                .otpSentToConfirmPhone,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                      if (isGoogleAuth) ...[
                        SizedBox(height: 1.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 1.h, horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8.sp),
                          ),
                          child: Text(
                            recipient,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.sp,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        Text(
                          AppLocalizations.of(context)!.checkInboxToContinue,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.sp,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 4.h),

                // OK button
                SizedBox(
                  width: double.infinity,
                  height: 5.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.sp),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.ok,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("OTP: Error showing message popup: $e");
    }
  }

  void _startResendTimer() {
    _timeLeft = 300; // 5 minutes
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatTimeLeft() {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _isTimeExpired => _timeLeft <= 0;

  Future<void> _verifyOtp() async {
    // Prevent double submission
    if (_otpSubmitted) {
      debugPrint("Log_Auth_flow: OTP - Ignoring duplicate submission");
      return;
    }

    final otpCode = _otpControllers.map((controller) => controller.text).join();
    debugPrint("Log_Auth_flow: OTP - Verifying OTP code: $otpCode");
    debugPrint(
        "Log_Auth_flow: OTP - Authentication type: ${widget.googleEmail != null ? 'Google Email' : 'Phone'}");

    // Check if OTP is empty or incomplete
    if (otpCode.isEmpty || otpCode.length < 6) {
      debugPrint("Log_Auth_flow: OTP - Invalid OTP code entered");
      setState(() {
        _otpError = AppLocalizations.of(context)!.enterValidOtp;
      });
      return;
    }

    // Get the auth provider for state management
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(
        "Log_Auth_flow: OTP - Current Google sign-in in progress flag: ${authProvider.isGoogleSignInInProgress}");

    setState(() {
      _otpError = null;
      _isLoading = true;
      _otpSubmitted = true; // Mark as submitted
    });
    debugPrint(
        "Log_Auth_flow: OTP - Set loading state and marked OTP as submitted");

    try {
      debugPrint(
          "Log_Auth_flow: OTP - Sending verification request via AuthProvider");
      final success = await authProvider.verifyOtp(otpCode);
      debugPrint("Log_Auth_flow: OTP - Verification result: $success");

      // Reset submission flag if still mounted (in case of errors)
      if (mounted) {
        setState(() {
          _otpSubmitted = false;
        });
        debugPrint("Log_Auth_flow: OTP - Reset submission flag");
      }

      if (success) {
        debugPrint(
            "Log_Auth_flow: OTP - Verification successful, preparing navigation");
        debugPrint(
            "Log_Auth_flow: OTP - Authentication status: ${authProvider.isAuthenticated}");
        debugPrint(
            "Log_Auth_flow: OTP - Google sign-in in progress: ${authProvider.isGoogleSignInInProgress}");

        // Show success dialog before navigating to home screen
        if (mounted) {
          debugPrint("OTP: Showing success dialog");
          await showDialog(
            context: context,
            builder: (context) => SuccessDialog(
              message: AppLocalizations.of(context)!.authSuccessful,
            ),
          ).then((_) {
            if (mounted) {
              _navigateAfterSuccess(context);
            }
          });
        }
      } else {
        debugPrint("OTP: Verification failed");

        if (mounted) {
          debugPrint("OTP: Showing error dialog");
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.error),
              content: Text(authProvider.error ??
                  AppLocalizations.of(context)!.authFailed),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint("OTP: Error dialog dismissed");
                    Navigator.of(context).pop(); // Dismiss dialog
                    setState(() {
                      _otpError = AppLocalizations.of(context)!.invalidOtp;
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("OTP: Verification error: $e");

      if (mounted) {
        setState(() {
          _otpError = AppLocalizations.of(context)!.errorPrefix(e.toString());
          _otpSubmitted = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to navigate after successful OTP verification
  void _navigateAfterSuccess(BuildContext context) {
    debugPrint(
        "Log_Auth_flow: OTP - Starting navigation after successful verification");

    // Check if there's a saved return path in URL parameters
    final uri = GoRouterState.of(context).uri;
    final returnTo = uri.queryParameters['returnTo'];
    debugPrint("Log_Auth_flow: OTP - Current URI: ${uri.toString()}");
    debugPrint("Log_Auth_flow: OTP - Return path from URL: $returnTo");

    // Store current context before navigation for showing snackbar later
    final navigatorKey = GlobalKey<NavigatorState>();

    // IMPROVED: Check if returnTo is valid and not a login or verify-otp path
    if (returnTo != null &&
        returnTo.isNotEmpty &&
        !returnTo.startsWith('/login') &&
        !returnTo.startsWith('/verify-otp')) {
      debugPrint(
          "Log_Auth_flow: OTP - Found valid returnTo parameter in URL: $returnTo");
      debugPrint("Log_Auth_flow: OTP - Navigating to returnTo path");

      try {
        // Use go to replace the current page in history and show success message
        // We'll add a small delay to ensure the success notification appears after navigation is complete
        context.go(returnTo);

        // Add a small delay before showing the notification to ensure navigation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (navigatorKey.currentContext != null) {
            showAuthSuccessNotification(navigatorKey.currentContext!);
          } else if (context.mounted) {
            showAuthSuccessNotification(context);
          }
        });

        debugPrint("Log_Auth_flow: OTP - Successfully navigated to $returnTo");
        return;
      } catch (e) {
        debugPrint("Log_Auth_flow: OTP - Error navigating to returnTo: $e");
        // Continue to fallback navigation options
      }
    } else if (returnTo != null) {
      debugPrint(
          "Log_Auth_flow: OTP - Found invalid returnTo path: $returnTo, ignoring");
    }

    // Try getting returnTo from SharedPreferences as backup if not found in URL
    _tryFallbackNavigation(context);
  }

  void _tryFallbackNavigation(BuildContext context) {
    debugPrint("Log_Auth_flow: OTP - Trying fallback navigation options");

    // Try reading returnTo from secure storage
    _readSavedReturnPath().then((savedReturnTo) {
      if (savedReturnTo != null &&
          savedReturnTo.isNotEmpty &&
          !savedReturnTo.startsWith('/login') &&
          !savedReturnTo.startsWith('/verify-otp')) {
        debugPrint(
            "Log_Auth_flow: OTP - Using saved return path: $savedReturnTo");

        if (context.mounted) {
          context.go(savedReturnTo);

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              showAuthSuccessNotification(context);
            }
          });
          return;
        }
      }

      // If no saved path or couldn't use it, try standard fallbacks
      _standardFallbackNavigation(context);
    }).catchError((e) {
      debugPrint("Log_Auth_flow: OTP - Error reading saved return path: $e");
      if (context.mounted) {
        _standardFallbackNavigation(context);
      }
    });
  }

  // Read return path from secure storage
  Future<String?> _readSavedReturnPath() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPath = await storage.read(key: 'previous_route_before_login');
      debugPrint("Log_Auth_flow: OTP - Read saved return path: $savedPath");
      if (savedPath != null) {
        await storage.delete(key: 'previous_route_before_login');
      }
      return savedPath;
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error reading saved path: $e");
      return null;
    }
  }

  // Standard fallbacks when no saved return paths are available
  void _standardFallbackNavigation(BuildContext context) {
    // If there's no valid returnTo in URL, try going back to previous screen
    try {
      final canPop = context.canPop();
      debugPrint("Log_Auth_flow: OTP - Can pop to previous screen: $canPop");

      if (canPop) {
        debugPrint("Log_Auth_flow: OTP - Popping back to previous screen");
        // IMPROVED: Pop with result to indicate successful authentication
        context.pop();

        // Show success message after navigation back
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            showAuthSuccessNotification(context);
          }
        });

        debugPrint("Log_Auth_flow: OTP - Successfully popped back");
        return;
      }
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error when trying to pop: $e");
    }

    // As a last resort, navigate to home
    debugPrint(
        "Log_Auth_flow: OTP - No valid return path found, going to home");
    try {
      debugPrint("Log_Auth_flow: OTP - Navigating to /home");
      context.go('/home');

      // Show success message on home screen
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          showAuthSuccessNotification(context);
        }
      });

      debugPrint("Log_Auth_flow: OTP - Successfully navigated to home");
    } catch (e) {
      debugPrint("Log_Auth_flow: OTP - Error navigating to home: $e");
    }
  }

  Future<void> _resendCode() async {
    if (_timeLeft > 0) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      bool success = false;
      final identifier = widget.googleEmail ?? widget.phoneNumber!;

      // Use the refreshOtp endpoint instead of the original authentication endpoints
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      success = await authProvider.refreshOtp(identifier);

      if (success) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.otpResentSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _otpError = authProvider.error ??
                AppLocalizations.of(context)!.failedToResendOtp;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpError = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add a method to clear all OTP fields
  void _clearOtpFields() {
    setState(() {
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpError = null;
    });

    // Focus the first field
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen metrics for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // Calculate header height - smaller when keyboard is visible
    final headerHeight = isKeyboardVisible
        ? screenHeight * 0.22 // Smaller header when keyboard is visible
        : screenHeight * 0.32; // Normal header height
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // Remove resizeToAvoidBottomInset: true to prevent screen jumping
      body: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green curved header with logo - adaptive height
              ClipPath(
                clipper: CurvedBottomClipper(),
                child: Container(
                  color: colorScheme.primary, // Primary green color
                  height: headerHeight,
                  width: double.infinity,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // Back button
                        Positioned(
                          top: 10,
                          left: 10,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.onPrimary,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: colorScheme.onSurfaceVariant,
                                size: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate logo size based on available height
                              final availableHeight = constraints.maxHeight -
                                  4.h; // Account for padding
                              final logoSize = math.min(
                                  isKeyboardVisible ? 20.w : 30.w,
                                  availableHeight);

                              return Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: Image.asset(
                                  'assets/images/auth/logo.png',
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.contain,
                                  // Use placeholder if logo not available
                                  errorBuilder: (ctx, obj, stack) => Icon(
                                    Icons.landscape,
                                    color: colorScheme.onPrimary,
                                    size: 18.w,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h), // Reduced spacing after header

              // Scrollable content area that adjusts for keyboard
              Expanded(
                child: GestureDetector(
                  // Dismiss keyboard when tapping outside input fields
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          AppLocalizations.of(context)!.otpVerification,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 1.5.h),

                        // Subtitle
                        Text(
                          widget.googleEmail != null
                              ? AppLocalizations.of(context)!.checkEmailForOtp
                              : AppLocalizations.of(context)!
                                  .checkMessageForOtp,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 3.h),

                        // OTP Code label and action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.otpCode,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            // Action buttons
                            Row(
                              children: [
                                // Clear button
                                IconButton(
                                  onPressed: _clearOtpFields,
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 20.sp,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  tooltip: AppLocalizations.of(context)!.clear,
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.all(2.w),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),

                        // OTP input fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => SizedBox(
                              width: 12.w,
                              height: 6.h,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                autofocus: index == 0,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(1),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  // A digit was entered
                                  if (value.isNotEmpty) {
                                    if (index < 5) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else {
                                      // This is the last field, check if all are filled
                                      final isOtpComplete = _otpControllers
                                          .every((c) => c.text.isNotEmpty);
                                      if (isOtpComplete) {
                                        _focusNodes[index].unfocus();
                                        _verifyOtp();
                                      }
                                    }
                                  }
                                  // A digit was deleted
                                  else {
                                    if (index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  }
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    borderSide: _otpError != null
                                        ? BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            width: 1.0)
                                        : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    borderSide: _otpError != null
                                        ? BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            width: 1.0)
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.sp),
                                    borderSide: _otpError != null
                                        ? BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            width: 1.5)
                                        : BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Error message
                        if (_otpError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 1.h, left: 1.w),
                            child: Text(
                              _otpError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        SizedBox(height: 4.h),

                        // Verify button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: SizedBox(
                            width: double.infinity,
                            height: 6.h,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _otpSubmitted)
                                  ? null
                                  : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                disabledBackgroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.sp),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 3.h,
                                      width: 3.h,
                                      child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          strokeWidth: 2.5))
                                  : Text(
                                      AppLocalizations.of(context)!.verify,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: 2.5.h),
                        // Resend code row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: (_timeLeft == 0 && !_isLoading)
                                  ? _resendCode
                                  : null,
                              child: Text(
                                AppLocalizations.of(context)!.resendCode,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: (_timeLeft == 0 && !_isLoading)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimeLeft(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),

                        // Add extra padding at the bottom to ensure everything is visible
                        SizedBox(
                          height: keyboardHeight > 0
                              ? keyboardHeight
                              : MediaQuery.of(context).padding.bottom + 2.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay - only shown when isLoading & otpSubmitted are both true
          if (_isLoading && _otpSubmitted)
            Container(
              color: colorScheme.scrim,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.sp),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom loading animation
                      SizedBox(
                        width: 15.w,
                        height: 15.w,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary.withAlpha(179),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      // Loading text
                      Text(
                        AppLocalizations.of(context)!.verifying,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // Subtext
                      Text(
                        AppLocalizations.of(context)!.verifyingYourCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating paste button for easier access
        ],
      ),
    );
  }
}

// Custom clipper for the curved bottom - matches login page exactly
class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate curve height as a smaller percentage of container height (8%)
    final curveHeight = size.height * 0.08;
    // Ensure curve offset doesn't exceed container bounds
    final safeOffset = math.min(curveHeight, size.height * 0.12);

    // Start from top-left corner
    path.lineTo(0, size.height - safeOffset);

    // Use a gentler quadratic Bezier curve for the entire width
    path.quadraticBezierTo(
      size.width / 2, // Control point x at center
      size.height +
          (safeOffset *
              0.1), // Control point y slightly below for gentler curve
      size.width, // End point x at right edge
      size.height - safeOffset, // End point y same as start
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
