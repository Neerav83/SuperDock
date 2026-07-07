import 'package:flutter/material.dart';

import '../theme/colors.dart';

IconData iconForKey(String key) {
  return _icons[key] ?? Icons.apps;
}

String iconKeyForData(IconData icon) {
  for (final entry in _icons.entries) {
    if (entry.value == icon) return entry.key;
  }
  return 'extension';
}

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.blue;
  final value = hex.replaceFirst('#', '').toUpperCase();
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  if (value.length == 8) {
    return Color(int.parse(value, radix: 16));
  }
  return AppColors.blue;
}

String normalizeColorHex(String? hex, {String fallback = '#3B82F6'}) {
  if (hex == null || hex.isEmpty) return fallback;
  final upper = hex.startsWith('#') ? hex.toUpperCase() : '#${hex.toUpperCase()}';
  if (colorOptions.containsKey(upper)) return upper;
  return fallback;
}

const _icons = <String, IconData>{
  'code': Icons.code,
  'auto_awesome': Icons.auto_awesome,
  'dns': Icons.dns,
  'design_services': Icons.design_services,
  'terminal': Icons.terminal,
  'play_arrow': Icons.play_arrow,
  'download': Icons.download,
  'phone_iphone': Icons.phone_iphone,
  'apple': Icons.apple,
  'language': Icons.language,
  'grid_view': Icons.grid_view,
  'storage': Icons.storage,
  'brush': Icons.brush,
  'folder': Icons.folder,
  'rocket_launch': Icons.rocket_launch,
  'extension': Icons.extension,
  'science': Icons.science,
  'build': Icons.build,
  'cloud': Icons.cloud,
  'star': Icons.star,
};

const iconOptions = <String, String>{
  'code': 'Code',
  'auto_awesome': 'AI',
  'dns': 'Server',
  'design_services': 'Design',
  'terminal': 'Terminal',
  'play_arrow': 'Run',
  'phone_iphone': 'Mobile',
  'storage': 'Storage',
  'brush': 'Creative',
  'grid_view': 'Grid',
  'rocket_launch': 'Launch',
  'extension': 'Extension',
  'science': 'Science',
  'build': 'Build',
  'cloud': 'Cloud',
  'star': 'Star',
};

const colorOptions = <String, String>{
  '#3B82F6': 'Blue',
  '#A855F7': 'Purple',
  '#4ADE80': 'Green',
  '#F97316': 'Orange',
  '#22D3EE': 'Cyan',
};
