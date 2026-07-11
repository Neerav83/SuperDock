import 'package:flutter/material.dart';

import '../theme/icon_registry.dart';

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.accentColorHex,
    this.shortcut,
    this.projectPath,
    this.imageUrl,
    this.actions = const [],
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String accentColorHex;
  final String? shortcut;
  final String? projectPath;
  final String? imageUrl;
  final List<Map<String, dynamic>> actions;

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final actions = json['actions'];
    final rawHex = json['accentColor'] as String?;
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      shortcut: json['shortcut'] as String?,
      projectPath: json['projectPath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      icon: iconForKey(json['icon'] as String? ?? 'grid_view'),
      accentColor: colorFromHex(rawHex),
      accentColorHex: normalizeColorHex(rawHex),
      actions: actions is List
          ? actions.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'shortcut': shortcut,
      'projectPath': projectPath,
      'imageUrl': imageUrl,
      'icon': _iconKey(icon),
      'accentColor': accentColorHex,
      'actions': actions,
    };
  }

  static String _iconKey(IconData icon) {
    for (final entry in iconOptions.entries) {
      if (iconForKey(entry.key) == icon) return entry.key;
    }
    return 'grid_view';
  }
}
