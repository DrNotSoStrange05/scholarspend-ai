import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/dues_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dues_manager_screen.dart';
import 'screens/login_screen.dart';
import 'screens/add_transaction_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Show login if not authenticated
                if (!authProvider.isLoggedIn) {
                  return const LoginScreen();
                }
                // Show dashboard if authenticated
                return const DashboardScreen();
              },
            ),
            routes: {
              '/dashboard': (_) => const DashboardScreen(),
              '/ledger': (_) => const LedgerScreen(),
              '/analytics': (_) => const AnalyticsScreen(),
              '/dues': (_) => Consumer<AuthProvider>(
                builder: (context, auth, _) => DuesManagerScreen(
                  userId: auth.userId ?? 1,
                ),
              ),
              '/add-transaction': (_) => const AddTransactionScreen(),
            },
          );
        },
      ),
    );
  }
}
