class FormulaEvaluator {
  /// Evaluates simple inline math strings like "12*24", "100+25", "500/2", "200-50"
  static double? tryEvaluate(String input) {
    final cleaned = input.replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;

    // Try direct number parse
    final direct = double.tryParse(cleaned);
    if (direct != null) return direct;

    // Check operators: + - * /
    try {
      if (cleaned.contains('+')) {
        final parts = cleaned.split('+');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a + b;
        }
      } else if (cleaned.contains('*')) {
        final parts = cleaned.split('*');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a * b;
        }
      } else if (cleaned.contains('/')) {
        final parts = cleaned.split('/');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null && b != 0) return a / b;
        }
      } else if (cleaned.contains('-') && !cleaned.startsWith('-')) {
        final parts = cleaned.split('-');
        if (parts.length == 2) {
          final a = double.tryParse(parts[0]);
          final b = double.tryParse(parts[1]);
          if (a != null && b != null) return a - b;
        }
      }
    } catch (_) {}

    return null;
  }
}

