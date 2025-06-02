// lib/models/monthly_summary.dart

/// Data model to hold summarized financial information for a month.
/// This is a calculated model, not directly stored in the database.
class MonthlySummary {
  final int month;
  final int year;
  final double totalMessMeals;
  final double totalMessExpenses;
  final double totalMessContributions;
  final double mealRate;
  final List<MemberBalance> memberBalances;

  MonthlySummary({
    required this.month,
    required this.year,
    required this.totalMessMeals,
    required this.totalMessExpenses,
    required this.totalMessContributions,
    required this.mealRate,
    required this.memberBalances,
  });

  @override
  String toString() {
    return 'MonthlySummary{month: $month, year: $year, totalMeals: $totalMessMeals, totalExpenses: $totalMessExpenses, totalContributions: $totalMessContributions, mealRate: $mealRate, memberBalances: $memberBalances}';
  }
}

/// Data model to hold individual member's financial balance within a month.
/// This is a calculated model, not directly stored in the database.
class MemberBalance {
  final int memberId;
  final String memberName;
  final double personalMeals;
  final double personalContributions;
  final double shareOfExpenses;
  final double balance; // Positive if owed, negative if owes

  MemberBalance({
    required this.memberId,
    required this.memberName,
    required this.personalMeals,
    required this.personalContributions,
    required this.shareOfExpenses,
    required this.balance,
  });

  @override
  String toString() {
    return 'MemberBalance{memberId: $memberId, memberName: $memberName, personalMeals: $personalMeals, personalContributions: $personalContributions, shareOfExpenses: $shareOfExpenses, balance: $balance}';
  }
}
