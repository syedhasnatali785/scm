import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/currency.dart';

class FxService {
  static const String _liveApiUrl = 'https://open.er-api.com/v6/latest/USD';

  /// Fetches live exchange rates against PKR as base currency
  static Future<Map<String, double>> fetchLiveRates() async {
    try {
      final response = await http
          .get(Uri.parse(_liveApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final rates = data['rates'] as Map<String, dynamic>;

          final usdToPkr = (rates['PKR'] as num?)?.toDouble() ?? 278.4;
          final usdToCny = (rates['CNY'] as num?)?.toDouble() ?? 7.10;
          final usdToEur = (rates['EUR'] as num?)?.toDouble() ?? 0.92;
          final usdToAed = (rates['AED'] as num?)?.toDouble() ?? 3.67;

          // Convert all to PKR base: 1 X = ? PKR
          final rmbToPkr = usdToCny > 0 ? (usdToPkr / usdToCny) : 39.20;
          final eurToPkr = usdToEur > 0 ? (usdToPkr / usdToEur) : 302.50;
          final aedToPkr = usdToAed > 0 ? (usdToPkr / usdToAed) : 75.80;

          debugPrint('Live FX fetched successfully: USD=$usdToPkr, RMB=$rmbToPkr');
          return {
            'PKR': 1.0,
            'USD': usdToPkr,
            'RMB': rmbToPkr,
            'EUR': eurToPkr,
            'AED': aedToPkr,
          };
        }
      }
    } catch (e) {
      debugPrint('Live FX API fetch failed, falling back to cached baseline: $e');
    }

    // Baseline cached fallback
    return {
      'PKR': 1.0,
      'USD': 278.40,
      'RMB': 39.20,
      'AED': 75.80,
      'EUR': 302.50,
    };
  }

  /// Refreshes currency rates list with live data and safety buffer
  static Future<Map<String, CurrencyRate>> refreshRatesWithBuffer(
    Map<String, CurrencyRate> currentRates,
  ) async {
    final live = await fetchLiveRates();
    final updated = <String, CurrencyRate>{};

    for (final entry in currentRates.entries) {
      final code = entry.key;
      final existing = entry.value;

      if (existing.isLocked || existing.isBase) {
        // Keep locked or base rate unchanged
        updated[code] = existing;
      } else if (live.containsKey(code)) {
        updated[code] = existing.copyWith(
          rateToBase: live[code]!,
          lastUpdated: DateTime.now(),
        );
      } else {
        updated[code] = existing;
      }
    }

    return updated;
  }
}

