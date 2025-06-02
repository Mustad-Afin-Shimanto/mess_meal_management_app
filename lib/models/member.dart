// lib/models/member.dart

import 'package:mess_meal_management_app/utils/app_constants.dart';

/// Represents a member of the mess. A user can be associated with a member.
class Member {
  int? id; // Primary Key
  String name;
  String? email; // Optional email

  Member({
    this.id,
    required this.name,
    this.email,
  });

  /// Converts a Member object into a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      AppConstants.columnMemberIdPk: id,
      AppConstants.columnMemberName: name,
      AppConstants.columnMemberEmail: email,
    };
  }

  /// Creates a Member object from a Map (e.g., from database query).
  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map[AppConstants.columnMemberIdPk],
      name: map[AppConstants.columnMemberName],
      email: map[AppConstants.columnMemberEmail],
    );
  }

  /// Creates a copy of the Member object with updated values.
  Member copyWith({
    int? id,
    String? name,
    String? email,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
