import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart';

import '../models/transaction.dart';
import '../models/forecast.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final Telephony _telephony = Telephony.instance;

  // ── State ─────────────────────────────────────────────────────
  List<Transaction> _transactions = [];
  SurvivalForecast? _forecast;
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────
  List<Transaction>    get transactions => _transactions;
  SurvivalForecast?    get forecast     => _forecast;
  bool                 get isLoading    => _isLoading;
  String?              get error        => _error;

  double get currentBalance   => _forecast?.currentBalance ?? 0.0;
  double get daysOfSurvival   => _forecast?.daysOfSurvival ?? 0.0;
  double get avgDailySpend    => _forecast?.avgDailySpend  ?? 0.0;

  // ── Survival color (green → yellow → red) ────────────────────
  String get survivalStatus {
    if (daysOfSurvival > 14) return 'safe';
    if (daysOfSurvival > 7)  return 'warning';
    return 'danger';
  }

  // ═══════════════════════════════════════════════════════════════
  // Data Loading
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadData(int userId) async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _api.fetchTransactions(userId),
        _api.fetchSurvivalForecast(userId),
      ]);
      _transactions = results[0] as List<Transaction>;
      _forecast     = results[1] as SurvivalForecast;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SMS Sync
  // ═══════════════════════════════════════════════════════════════

  /// Called from the SMS background listener. Sends the new SMS to
  /// the backend and refreshes state.
  Future<void> syncSms(int userId, List<String> rawMessages) async {
    _setLoading(true);
    try {
      await _api.syncSms(userId, rawMessages);
      await loadData(userId);   // Refresh after sync
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SMS Listener (Android — Telephony plugin)
  // ═══════════════════════════════════════════════════════════════

  /// Call this once from initState of DashboardScreen.
  /// Listens for incoming SMS and auto-syncs financial messages.
  void startSmsListener(int userId) {
    // Request SMS permission
    _telephony.requestSmsPermissions;

    // Foreground listener
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final body = message.body ?? '';
        if (_isFinancialSms(body)) {
          syncSms(userId, [body]);
        }
      },
      // Background handler must be a top-level function (see sms_handler.dart)
      onBackgroundMessage: backgroundSmsHandler,
    );
  }

  /// Heuristic filter: only process bank/wallet SMS alerts.
  bool _isFinancialSms(String body) {
    final patterns = [
      'debited', 'credited', 'Rs.', 'INR', '₹',
      'UPI', 'payment', 'transaction',
    ];
    final lower = body.toLowerCase();
    return patterns.any((p) => lower.contains(p.toLowerCase()));
  }

  // ═══════════════════════════════════════════════════════════════
  // Native MethodChannel fallback (if telephony plugin unavailable)
  // ═══════════════════════════════════════════════════════════════

  static const _channel = MethodChannel('com.scholarspend/sms');

  /// Register a MethodChannel handler if you choose to implement
  /// the Android native receiver manually instead of the plugin.
  void setupMethodChannel(int userId) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final body = call.arguments as String;
        if (_isFinancialSms(body)) {
          await syncSms(userId, [body]);
        }
      }
    });
  }

  // ── Private helpers ───────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}

/// Top-level background SMS handler (required by telephony plugin).
/// Must be defined outside any class.
@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) {
  // Background isolate: cannot use Provider directly.
  // Persist raw_text to shared_preferences and sync on next app foreground.
  debugPrint('[BG SMS] Received: ${message.body}');
}
