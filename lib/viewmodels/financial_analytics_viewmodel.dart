import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class FinancialSensitivityState {
  final double rmbRateOverride;
  final double usdRateOverride;
  final int demurrageDays;
  final double demurrageDailyRateUsd;
  final double targetMarkupOverride;

  const FinancialSensitivityState({
    this.rmbRateOverride = 39.50,
    this.usdRateOverride = 278.50,
    this.demurrageDays = 0,
    this.demurrageDailyRateUsd = 120.0,
    this.targetMarkupOverride = 25.0,
  });

  FinancialSensitivityState copyWith({
    double? rmbRateOverride,
    double? usdRateOverride,
    int? demurrageDays,
    double? demurrageDailyRateUsd,
    double? targetMarkupOverride,
  }) {
    return FinancialSensitivityState(
      rmbRateOverride: rmbRateOverride ?? this.rmbRateOverride,
      usdRateOverride: usdRateOverride ?? this.usdRateOverride,
      demurrageDays: demurrageDays ?? this.demurrageDays,
      demurrageDailyRateUsd: demurrageDailyRateUsd ?? this.demurrageDailyRateUsd,
      targetMarkupOverride: targetMarkupOverride ?? this.targetMarkupOverride,
    );
  }
}

class FinancialAnalyticsViewModel extends StateNotifier<FinancialSensitivityState> {
  FinancialAnalyticsViewModel() : super(const FinancialSensitivityState());

  void setRmbRate(double rate) {
    state = state.copyWith(rmbRateOverride: rate);
  }

  void setUsdRate(double rate) {
    state = state.copyWith(usdRateOverride: rate);
  }

  void setDemurrageDays(int days) {
    state = state.copyWith(demurrageDays: days);
  }

  void setDemurrageRate(double rate) {
    state = state.copyWith(demurrageDailyRateUsd: rate);
  }

  void setTargetMarkup(double markup) {
    state = state.copyWith(targetMarkupOverride: markup);
  }

  void reset() {
    state = const FinancialSensitivityState();
  }
}

final financialAnalyticsViewModelProvider =
    StateNotifierProvider<FinancialAnalyticsViewModel, FinancialSensitivityState>((ref) {
  return FinancialAnalyticsViewModel();
});

