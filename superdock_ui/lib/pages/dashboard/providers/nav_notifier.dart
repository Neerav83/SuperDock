import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardNavProvider =
    NotifierProvider<DashboardNavNotifier, int>(DashboardNavNotifier.new);

class DashboardNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setSelectedNav(int index) {
    state = index;
  }
}
