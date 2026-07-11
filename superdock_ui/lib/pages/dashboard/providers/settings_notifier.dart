import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:superdock_ui/core/services/services.dart';

final dashboardSettingsProvider =
    NotifierProvider<DashboardSettingsNotifier, AppSettings>(
  DashboardSettingsNotifier.new,
);

class DashboardSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return const AppSettings(
      backendUrl: SettingsService.defaultBackendUrl,
    );
  }

  Future<AppSettings> ensureLoaded() async {
    final loaded = await ref.read(settingsServiceProvider).load();
    if (ref.mounted) state = loaded;
    return loaded;
  }

  Future<AppSettings> save(AppSettings settings) async {
    final saved = await ref.read(settingsServiceProvider).save(settings);
    if (ref.mounted) state = saved;
    return saved;
  }
}
