import 'package:flutter/material.dart';

class SnackBarHelper {
  /// Shows a SnackBar above the floating action button
  static void showSnackBarAboveFAB(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(
        bottom: 80.0, // Position above floating action button
        left: 16.0,
        right: 16.0,
      ),
      action: action,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a success SnackBar above the floating action button
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBarAboveFAB(
      context,
      message: message,
      backgroundColor: Colors.green,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error SnackBar above the floating action button
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBarAboveFAB(
      context,
      message: message,
      backgroundColor: Colors.red,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning SnackBar above the floating action button
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBarAboveFAB(
      context,
      message: message,
      backgroundColor: Colors.orange,
      duration: duration,
      action: action,
    );
  }

  /// Shows an info SnackBar above the floating action button
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBarAboveFAB(
      context,
      message: message,
      backgroundColor: Colors.blue,
      duration: duration,
      action: action,
    );
  }
}
