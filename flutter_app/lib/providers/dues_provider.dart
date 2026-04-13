import 'package:flutter/foundation.dart';

import '../models/due.dart';
import '../services/api_service.dart';

class DuesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Due> _dues = [];
  bool _isLoading = false;
  String? _error;

  List<Due> get dues         => _dues;
  bool       get isLoading   => _isLoading;
  String?    get error       => _error;

  List<Due> get iOwe        => _dues.where((d) => !d.isOwedToMe).toList();
  List<Due> get owedToMe    => _dues.where((d) => d.isOwedToMe).toList();

  Future<void> loadDues(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dues = await _api.fetchDues(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDue(int userId, Map<String, dynamic> payload) async {
    try {
      final due = await _api.createDue(userId, payload);
      _dues.insert(0, due);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markPaid(int dueId) async {
    try {
      await _api.markDuePaid(dueId);
      _dues.removeWhere((d) => d.id == dueId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
