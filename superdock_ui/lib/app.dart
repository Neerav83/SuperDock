import 'package:flutter/material.dart';

import 'core/theme/scroll_behavior.dart';
import 'core/theme/theme.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_page.dart';

class SuperDockApp extends StatelessWidget {
  const SuperDockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      scrollBehavior: const SuperDockScrollBehavior(),
      home: const DashboardPage(),
    );
  }
}
