//  # ✅ Enum: TimeRange.daily / weekly / etc

// File: lib/enums/time_range.dart

enum TimeRange {
  daily,
  weekly,
  monthly,
  yearly,
}

extension TimeRangeExtension on TimeRange {
  /// Label for buttons/UI
  String get label {
    switch (this) {
      case TimeRange.daily: return 'Daily';
      case TimeRange.weekly: return 'Weekly';
      case TimeRange.monthly: return 'Monthly';
      case TimeRange.yearly: return 'Yearly';
    }
  }

  /// Return start time based on current time
  DateTime getStartTime(DateTime now) {
    switch (this) {
      case TimeRange.daily:
        return now.subtract(const Duration(days: 1));
      case TimeRange.weekly:
        return now.subtract(const Duration(days: 7));
      case TimeRange.monthly:
        return now.subtract(const Duration(days: 30));
      case TimeRange.yearly:
        return now.subtract(const Duration(days: 365));
    }
  }
}
