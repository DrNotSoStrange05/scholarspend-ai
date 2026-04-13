import 'package:dio/dio.dart';

import '../models/analytics_summary.dart';
import '../models/due.dart';
import '../models/forecast.dart';
import '../models/transaction.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2/api'; // Android emulator → host

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // ── Transactions ─────────────────────────────────────────────
  Future<List<Transaction>> fetchTransactions(int userId, {int limit = 50}) async {
    final response = await _dio.get(
      '/transactions/',
      queryParameters: {'user_id': userId, 'limit': limit},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> syncSms(int userId, List<String> rawMessages) async {
    final body = {
      'user_id': userId,
      'sms_messages': rawMessages
          .map((msg) => {'raw_text': msg, 'received_at': null})
          .toList(),
    };
    await _dio.post('/transactions/sync', data: body);
  }

  Future<void> createTransaction(int userId, Map<String, dynamic> payload) async {
    await _dio.post(
      '/transactions/',
      queryParameters: {'user_id': userId},
      data: payload,
    );
  }

  // ── Analytics ─────────────────────────────────────────────────
  Future<SurvivalForecast> fetchSurvivalForecast(int userId) async {
    final response = await _dio.get(
      '/analytics/survival-forecast',
      queryParameters: {'user_id': userId},
    );
    return SurvivalForecast.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AnalyticsSummary> fetchAnalyticsSummary(int userId) async {
    final response = await _dio.get(
      '/analytics/summary',
      queryParameters: {'user_id': userId},
    );
    return AnalyticsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Dues ──────────────────────────────────────────────────────
  Future<List<Due>> fetchDues(int userId, {bool includePaid = false}) async {
    final response = await _dio.get(
      '/dues/',
      queryParameters: {'user_id': userId, 'include_paid': includePaid},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => Due.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Due> createDue(int userId, Map<String, dynamic> payload) async {
    final response = await _dio.post(
      '/dues/',
      queryParameters: {'user_id': userId},
      data: payload,
    );
    return Due.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Due> markDuePaid(int dueId) async {
    final response = await _dio.patch('/dues/$dueId/pay');
    return Due.fromJson(response.data as Map<String, dynamic>);
  }
}
