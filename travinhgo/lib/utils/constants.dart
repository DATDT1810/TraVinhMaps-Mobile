import 'package:flutter/material.dart';
import 'env_config.dart';

const kcontentColor = Color(0xffF5F5F5);
const kbackgroundColor = Colors.white;
const kprimaryColor = Color(0xff158247);
const kSearchBackgroundColor = Color(0xffeeeeee);
const kpriceColor = Color(0xffF94F43);
const KnewNotificationBackgroundColor = Color(0xffD1F8FF);

String get Base_api => "${EnvConfig.apiBaseUrl}/";

// Show authentication success notification
void showAuthSuccessNotification(BuildContext context, {String? message}) {
  // First clear any existing snackbars
  ScaffoldMessenger.of(context).clearSnackBars();

  // Show a more visually appealing snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: kprimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message ?? 'Login successful!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: kprimaryColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );

  // Optionally, you could also show a brief overlay animation
  // This is more noticeable than just a snackbar
  showAuthSuccessOverlay(context);
}

// Show a brief success overlay animation
void showAuthSuccessOverlay(BuildContext context) {
  // Create an overlay entry
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity:
                  value > 0.8 ? 2.0 - value * 2.0 : value, // Fade in then out
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kprimaryColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            // Remove the overlay when animation completes
            overlayEntry.remove();
          },
        ),
      ),
    ),
  );

  // Add the overlay to the overlay state
  overlayState.insert(overlayEntry);
}
