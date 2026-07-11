import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:superdock_ui/core/services/services.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});
