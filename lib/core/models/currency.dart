import 'package:flutter/foundation.dart';

@immutable
class CurrencyRate {
  final String code;
  final String name;
  final String symbol;
  final double rateToBase;
  final double safetyBufferPct;
  final bool isLocked;
  final bool isBase;
  final DateTime lastUpdated;

  const CurrencyRate({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rateToBase,
    this.safetyBufferPct = 1.0,
    this.isLocked = false,
    this.isBase = false,
    required this.lastUpdated,
  });

  /// Effective exchange rate accounting for FX volatility buffer
  double get effectiveRate {
    if (isBase) return 1.0;
    return rateToBase * (1.0 + (safetyBufferPct / 100.0));
  }

  CurrencyRate copyWith({
    String? code,
    String? name,
    String? symbol,
    double? rateToBase,
    double? safetyBufferPct,
    bool? isLocked,
    bool? isBase,
    DateTime? lastUpdated,
  }) {
    return CurrencyRate(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      rateToBase: rateToBase ?? this.rateToBase,
      safetyBufferPct: safetyBufferPct ?? this.safetyBufferPct,
      isLocked: isLocked ?? this.isLocked,
      isBase: isBase ?? this.isBase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static List<CurrencyRate> defaultCurrencies() {
    final now = DateTime.now();
    return [
      CurrencyRate(
        code: 'PKR',
        name: 'Pakistani Rupee',
        symbol: '₨',
        rateToBase: 1.0,
        safetyBufferPct: 0.0,
        isBase: true,
        isLocked: true,
        lastUpdated: now,
      ),
      CurrencyRate(
        code: 'RMB',
        name: 'Chinese Yuan',
        symbol: '¥',
        rateToBase: 39.20,
        safetyBufferPct: 1.5,
        isBase: false,
        isLocked: false,
        lastUpdated: now,
      ),
      CurrencyRate(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        rateToBase: 278.40,
        safetyBufferPct: 1.0,
        isBase: false,
        isLocked: false,
        lastUpdated: now,
      ),
      CurrencyRate(
        code: 'AED',
        name: 'UAE Dirham',
        symbol: 'AED',
        rateToBase: 75.80,
        safetyBufferPct: 1.0,
        isBase: false,
        isLocked: false,
        lastUpdated: now,
      ),
      CurrencyRate(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        rateToBase: 302.50,
        safetyBufferPct: 1.0,
        isBase: false,
        isLocked: false,
        lastUpdated: now,
      ),
    ];
  }
}

