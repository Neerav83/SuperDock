import 'package:flutter/material.dart';

import '../theme/icon_registry.dart';

class DockAction {
  const DockAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.status,
    required this.accentColor,
    this.appName,
    this.shellCommand,
    this.usesFlutterProject = false,
    this.usesGitProject = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final String status;
  final Color accentColor;
  final String? appName;
  final String? shellCommand;
  final bool usesFlutterProject;
  final bool usesGitProject;

  factory DockAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'open_app';
    return DockAction(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: iconForKey(json['icon'] as String? ?? 'apps'),
      status: json['status'] as String? ?? '',
      accentColor: colorFromHex(json['accentColor'] as String?),
      appName: type == 'open_app' ? json['appName'] as String? : null,
      shellCommand: type == 'shell' ? json['cmd'] as String? : null,
      usesFlutterProject: json['usesFlutterProject'] as bool? ?? false,
      usesGitProject: json['usesGitProject'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final type = appName != null ? 'open_app' : 'shell';
    final json = <String, dynamic>{
      'id': id,
      'title': title,
      'icon': iconKeyForData(icon),
      'status': status,
      'accentColor': '#${accentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'type': type,
    };
    if (appName != null) json['appName'] = appName;
    if (shellCommand != null) json['cmd'] = shellCommand;
    if (usesFlutterProject) json['usesFlutterProject'] = usesFlutterProject;
    if (usesGitProject) json['usesGitProject'] = usesGitProject;
    return json;
  }
}
