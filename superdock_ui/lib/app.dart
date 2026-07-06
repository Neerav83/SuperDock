import 'package:flutter/material.dart';

import 'core/theme/theme.dart';
import 'pages/dashboard_page.dart';

class SuperDockApp extends StatelessWidget {
  const SuperDockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const DashboardPage(),
    );
  }
}
