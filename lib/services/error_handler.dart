import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

/// A centralized error handling service for the app
class ErrorHandler {
  /// Shows an error snackbar with consistent styling
  static void showErrorSnackBar(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success snackbar with consistent styling
  static void showSuccessSnackBar(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an info snackbar with consistent styling
  static void showInfoSnackBar(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a warning snackbar with consistent styling
  static void showWarningSnackBar(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Converts Firebase errors to user-friendly messages
  static String getFirebaseErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service is currently unavailable. Please try again later.';
        case 'unauthenticated':
          return 'You need to be logged in to perform this action.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'already-exists':
          return 'The data already exists.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'failed-precondition':
          return 'Operation failed due to invalid state.';
        case 'out-of-range':
          return 'Operation was attempted past the valid range.';
        case 'data-loss':
          return 'Unrecoverable data loss or corruption.';
        case 'internal':
          return 'Internal server error occurred.';
        case 'invalid-argument':
          return 'Invalid data provided.';
        case 'deadline-exceeded':
          return 'Operation timed out. Please try again.';
        case 'cancelled':
          return 'Operation was cancelled.';
        default:
          return 'An error occurred: ${error.message ?? error.code}';
      }
    }

    // Handle network errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Handle other common errors
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }

    return error.toString();
  }

  /// Handles async operations with automatic error handling
  static Future<void> handleAsyncError(
      BuildContext context,
      Future<void> Function() operation,
      {
        String? successMessage,
        String? errorPrefix,
        bool showLoadingIndicator = false,
      }
      ) async {
    if (showLoadingIndicator) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    try {
      await operation();

      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (successMessage != null && context.mounted) {
        showSuccessSnackBar(context, successMessage);
      }
    } catch (error) {
      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (context.mounted) {
        final message = errorPrefix != null
            ? '$errorPrefix: ${getFirebaseErrorMessage(error)}'
            : getFirebaseErrorMessage(error);
        showErrorSnackBar(context, message);
      }

      // Log error for debugging
      debugPrint('ErrorHandler: $error');
    }
  }

  /// Shows a confirmation dialog with consistent styling
  static Future<bool> showConfirmationDialog(
      BuildContext context, {
        required String title,
        required String content,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
        bool isDestructive = false,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              isDestructive ? Icons.warning_outlined : Icons.help_outline,
              color: isDestructive ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : null,
              foregroundColor: isDestructive ? Colors.white : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Checks internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Executes an operation only if internet is available
  static Future<void> checkConnectivityAndExecute(
      BuildContext context,
      Future<void> Function() operation,
      {String noConnectionMessage = 'No internet connection. Please check your network and try again.'}
      ) async {
    if (await hasInternetConnection()) {
      await operation();
    } else {
      if (context.mounted) {
        showErrorSnackBar(context, noConnectionMessage);
      }
    }
  }

  /// Shows a loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Hides the current loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  // ========================================
  // ADDED METHODS FOR NEW ADMIN FEATURES
  // ========================================

  /// Method to handle Firebase errors with user-friendly messages (Alternative signature)
  static void showFirebaseError(BuildContext context, dynamic error) {
    final userFriendlyMessage = getFirebaseErrorMessage(error);
    showErrorSnackBar(context, userFriendlyMessage);
  }

  /// Method to show custom snackbar with any color and icon
  static void showCustomSnackBar(
      BuildContext context,
      String message,
      Color backgroundColor,
      IconData icon,
      {Duration duration = const Duration(seconds: 3)}
      ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Alternative confirmation dialog signature for compatibility
  static Future<bool?> showConfirmationDialogAlt(
      BuildContext context,
      String title,
      String message,
      {String confirmText = 'Confirm',
        String cancelText = 'Cancel',
        Color confirmColor = Colors.red}
      ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// Shows a simple loading dialog with just spinner (for quick operations)
  static void showSimpleLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  /// Shows a detailed loading dialog with message and progress
  static void showDetailedLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}