import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/transaction_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ledger_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScholarSpendApp());
}

class ScholarSpendApp extends StatelessWidget {
  const ScholarSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'ScholarSpend AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const DashboardScreen(),
          '/ledger': (_) => const LedgerScreen(),
        },
      ),
    );
  }
}
