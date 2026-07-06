import 'package:flutter/material.dart';

import '../theme/colors.dart';

class WorkspaceUiMeta {
  const WorkspaceUiMeta({
    required this.icon,
    required this.accentColor,
  });

  final IconData icon;
  final Color accentColor;
}

const defaultWorkspaceUiMeta = WorkspaceUiMeta(
  icon: Icons.grid_view,
  accentColor: AppColors.blue,
);

const workspaceUiMetaById = <String, WorkspaceUiMeta>{
  'flutter-dev': WorkspaceUiMeta(
    icon: Icons.phone_iphone,
    accentColor: AppColors.purple,
  ),
  'ai-mode': WorkspaceUiMeta(
    icon: Icons.auto_awesome,
    accentColor: AppColors.purple,
  ),
  'server-mode': WorkspaceUiMeta(
    icon: Icons.storage,
    accentColor: AppColors.blue,
  ),
  'design-mode': WorkspaceUiMeta(
    icon: Icons.brush,
    accentColor: AppColors.orange,
  ),
};

WorkspaceUiMeta workspaceUiMetaFor(String id) {
  return workspaceUiMetaById[id] ?? defaultWorkspaceUiMeta;
}
