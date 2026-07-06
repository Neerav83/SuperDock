import 'package:flutter/material.dart';

class DockAction {
  const DockAction({
    required this.title,
    required this.icon,
    required this.status,
    required this.accentColor,
    this.appName,
    this.shellCommand,
  });

  final String title;
  final IconData icon;
  final String status;
  final Color accentColor;
  final String? appName;
  final String? shellCommand;
}
