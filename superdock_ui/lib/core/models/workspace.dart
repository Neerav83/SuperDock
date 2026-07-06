import 'package:flutter/material.dart';

class Workspace {
  const Workspace({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.shortcut,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? shortcut;
}
