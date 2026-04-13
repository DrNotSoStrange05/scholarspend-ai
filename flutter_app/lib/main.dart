import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/dues_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dues_manager_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScholarSpendApp());
}

class ScholarSpendApp extends StatefulWidget {
  const ScholarSpendApp({super.key});

  @override
  State<ScholarSpendApp> createState() => _ScholarSpendAppState();
}

class _ScholarSpendAppState extends State<ScholarSpendApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => DuesProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'ScholarSpend AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            initialRoute: '/',
            routes: {
              '/': (_) => const DashboardScreen(),
              '/ledger': (_) => const LedgerScreen(),
              '/analytics': (_) => const AnalyticsScreen(),
              '/dues': (_) => const DuesManagerScreen(userId: 1),
            },
          );
        },
      ),
    );
  }
}
