import 'package:flutter/material.dart';

/// Visar en modal som inte stängs av misstags-tap (vanligt med iPad som andra skärm).
Future<T?> showSuperDockDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (context) => FocusScope(
      autofocus: true,
      child: builder(context),
    ),
  );
}
