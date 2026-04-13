import 'package:flutter/foundation.dart';

import '../models/analytics_summary.dart';
import '../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AnalyticsSummary? _summary;
  bool _isLoading = false;
  String? _error;

  AnalyticsSummary? get summary     => _summary;
  bool              get isLoading   => _isLoading;
  String?           get error       => _error;

  Future<void> loadSummary(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _api.fetchAnalyticsSummary(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
