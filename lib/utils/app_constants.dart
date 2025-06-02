// lib/utils/app_constants.dart
/// Defines global constants used throughout the application.
class AppConstants {
  // Padding and spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // Text strings
  static const String appTitle = 'Mess Meal Management';
  static const String loginButton = 'Login';
  static const String registerButton = 'Register';
  static const String adminLoginTitle = 'Admin Login';
  static const String memberLoginTitle = 'Member Login';
  static const String usernameHint = 'Username';
  static const String passwordHint = 'Password';
  static const String confirmPasswordHint = 'Confirm Password';
  static const String nameHint = 'Name';
  static const String emailHint = 'Email (Optional)';
  static const String saveButton = 'Save';
  static const String deleteButton = 'Delete';
  static const String editButton = 'Edit';
  static const String recordButton = 'Record';
  static const String viewButton = 'View';
  static const String manageButton = 'Manage';
  static const String logoutButton = 'Logout';
  static const String resetDatabaseButton = 'Reset Database';
  static const String toggleActiveStatus = 'Toggle Active';
  static const String changeRole = 'Change Role';
  static const String deleteUser = 'Delete User';
  static const String recordMeals = 'Record Meals';
  static const String recordExpense = 'Record Expense';
  static const String manageContributions = 'Manage Contributions';
  static const String marketSchedule = 'Market Schedule';
  static const String financialReport = 'Financial Report';
  static const String profile = 'Profile';
  static const String personalMealHistory = 'Personal Meal History';
  static const String personalContributionHistory = 'Personal Contribution History';
  static const String personalExpenseHistory = 'Personal Expense History';
  static const String personalMarketDuty = 'Personal Market Duty';
  static const String registrationScreenTitle = 'Register Admin';
  static const String adminDashboard = 'Admin Dashboard';
  static const String managerDashboard = 'Manager Dashboard';
  static const String memberDashboard = 'Member Dashboard';
  static const String predictedExpenses = 'Predicted Expenses';
  static const String expenseAnalysis = 'Expense Analysis';
  static const String viewDailyMeals = 'View/Edit Daily Meals'; // New constant for the new screen title/button
  static const String dailyMealEntries = 'Daily Meal Entries'; // New constant for the app bar title of the new screen


  // Database constants
  static const String databaseName = 'mess_management.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableUsers = 'users';
  static const String tableMembers = 'members';
  static const String tableMealEntries = 'meal_entries';
  static const String tableExpenses = 'expenses';
  static const String tableContributions = 'contributions';
  static const String tableMarketSchedules = 'market_schedules';

  // Column names for users table
  static const String columnUserId = 'id';
  static const String columnUsername = 'username';
  static const String columnPasswordHash = 'password_hash'; // Storing hashed password
  static const String columnUserRole = 'role';
  static const String columnIsActive = 'is_active';
  static const String columnMemberId = 'member_id'; // Foreign key to members table

  // Column names for members table
  static const String columnMemberIdPk = 'id'; // Primary key for members
  static const String columnMemberName = 'name';
  static const String columnMemberEmail = 'email';

  // Column names for meal_entries table
  static const String columnMealEntryId = 'id';
  static const String columnMealMemberId = 'member_id'; // Foreign key
  static const String columnMealDate = 'meal_date';
  static const String columnBreakfastMeals = 'breakfast_meals';
  static const String columnLunchMeals = 'lunch_meals';
  static const String columnDinnerMeals = 'dinner_meals';
  static const String columnGuestMeals = 'guest_meals'; // For guest meal tracking

  // Column names for expenses table
  static const String columnExpenseId = 'id';
  static const String columnExpenseDate = 'expense_date';
  static const String columnExpenseAmount = 'amount';
  static const String columnExpenseDescription = 'description';

  // Column names for contributions table
  static const String columnContributionId = 'id';
  static const String columnContributionMemberId = 'member_id'; // Foreign key (who contributed)
  static const String columnContributionDate = 'contribution_date';
  static const String columnContributionAmount = 'amount';

  // Column names for market_schedules table (UPDATED: Added duty_title)
  static const String columnMarketScheduleId = 'id';
  static const String columnMarketMemberId = 'member_id';
  static const String columnMarketScheduleDate = 'schedule_date';
  static const String columnMarketDutyTitle = 'duty_title'; // New: For duty title
  static const String columnMarketDescription = 'description';

  // User role string values
  static const String roleAdmin = 'Admin';
  static const String roleManager = 'Manager';
  static const String roleMember = 'Member';
  static const String roleNone = 'None';
}
