import 'package:flutter/material.dart';
import 'package:superdock_ui/core/theme/tokens.dart';

void showDashboardError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.orange,
    ),
  );
}

void showDashboardInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String formatDashboardError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
