import 'dart:async';
import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 2),
  String? actionLabel,
  VoidCallback? onAction,
  Color? backgroundColor,
  bool showCloseIcon = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: showCloseIcon,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    ),
  );

  // Guarantee auto-close even if OS accessibility flags (e.g. on Windows/web) disable Flutter's default timer
  Timer(duration, () {
    try {
      controller.close();
    } catch (_) {}
  });
}
