import 'package:flutter/material.dart';

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.shortcut,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? shortcut;

  factory Workspace.fromJson(
    Map<String, dynamic> json, {
    required IconData icon,
    required Color accentColor,
  }) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortcut: json['shortcut'] as String?,
      icon: icon,
      accentColor: accentColor,
    );
  }
}
