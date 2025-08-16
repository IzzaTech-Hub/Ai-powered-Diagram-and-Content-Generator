import 'package:flutter/material.dart';

class ErrorHandler {
  /// Show a user-friendly error message with appropriate styling
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onRetry();
              },
              child: const Text(
                'RETRY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: Colors.red.shade600,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show a success message with appropriate styling
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show a warning message with appropriate styling
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade600,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Convert technical errors to user-friendly messages
  static String getFriendlyErrorMessage(String error) {
    error = error.toLowerCase();

    if (error.contains('connection refused') || error.contains('connection error')) {
      return 'Unable to connect to the server. The backend server is not running. Please start it by running "python app.py" in the backend directory, or check if the production server is available.';
    }

    if (error.contains('timeout')) {
      return 'The request timed out. Please try again or check your connection.';
    }

    if (error.contains('404') || error.contains('not found')) {
      return 'The requested resource was not found. Please try again later.';
    }

    if (error.contains('500') || error.contains('internal server error')) {
      return 'A server error occurred. Please try again later.';
    }

    if (error.contains('400') || error.contains('bad request')) {
      return 'Invalid request. Please check your input and try again.';
    }

    if (error.contains('401') || error.contains('unauthorized')) {
      return 'Authentication failed. Please check your credentials.';
    }

    if (error.contains('403') || error.contains('forbidden')) {
      return 'Access denied. You don\'t have permission to perform this action.';
    }

    if (error.contains('network') || error.contains('no internet')) {
      return 'Network error. Please check your internet connection.';
    }

    if (error.contains('json') || error.contains('format')) {
      return 'Invalid data format received. Please try again.';
    }

    // If no specific match, return a generic but helpful message
    if (error.isNotEmpty) {
      return 'An error occurred: ${error.length > 100 ? error.substring(0, 100) + '...' : error}';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Show an error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('RETRY'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}