import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:superdock_ui/core/services/services.dart';
import 'package:superdock_ui/pages/dashboard/providers/settings_notifier.dart';

final superDockApiProvider =
    NotifierProvider<SuperDockApiNotifier, SuperDockApi>(SuperDockApiNotifier.new);

class SuperDockApiNotifier extends Notifier<SuperDockApi> {
  @override
  SuperDockApi build() {
    final settings = ref.watch(dashboardSettingsProvider);
    return SuperDockApi(baseUrl: settings.backendUrl);
  }
}
