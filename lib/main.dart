// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Needed for date pickers
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/services/auth_service.dart';
import 'package:mess_meal_management_app/services/meal_service.dart';
import 'package:mess_meal_management_app/services/expense_service.dart';
import 'package:mess_meal_management_app/services/member_service.dart';
import 'package:mess_meal_management_app/services/market_schedule_service.dart';
import 'package:mess_meal_management_app/services/contribution_service.dart';

// import 'package:mess_meal_management_app/database/database_helper.dart'; // Removed: Unused import
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/providers/market_schedule_provider.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';

// Import all screen files directly for routing
import 'package:mess_meal_management_app/screens/auth/splash_screen.dart';
import 'package:mess_meal_management_app/screens/auth/registration_screen.dart';
import 'package:mess_meal_management_app/screens/auth/admin_login_screen.dart';
import 'package:mess_meal_management_app/screens/auth/member_login_screen.dart';
import 'package:mess_meal_management_app/screens/admin/admin_dashboard_screen.dart';
import 'package:mess_meal_management_app/screens/manager/manager_dashboard_screen.dart';
import 'package:mess_meal_management_app/screens/manager/record_meals_screen.dart';
import 'package:mess_meal_management_app/screens/manager/record_expense_screen.dart';
import 'package:mess_meal_management_app/screens/manager/manage_contributions_screen.dart';
import 'package:mess_meal_management_app/screens/manager/market_schedule_screen.dart';
import 'package:mess_meal_management_app/screens/member/member_dashboard_screen.dart';
import 'package:mess_meal_management_app/screens/shared/financial_report_screen.dart';
import 'package:mess_meal_management_app/screens/shared/profile_screen.dart';
import 'package:mess_meal_management_app/screens/member/personal_meal_history_screen.dart';
import 'package:mess_meal_management_app/screens/member/personal_contribution_history_screen.dart';
import 'package:mess_meal_management_app/screens/member/personal_expense_history_screen.dart';
import 'package:mess_meal_management_app/screens/member/personal_market_duty_screen.dart';
import 'package:mess_meal_management_app/screens/shared/expense_analysis_screen.dart';
// import 'package:mess_meal_management_app/screens/manager/daily_meal_entries_screen.dart'; // Removed: Not used in routes map


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // DatabaseHelper is a singleton and initializes on first access of 'database' getter.
  // Services will get their own instance of DatabaseHelper internally, as designed.

  // Initialize services. They internally create their own DatabaseHelper instance.
  final AuthService authService = AuthService();
  final MealService mealService = MealService();
  final ExpenseService expenseService = ExpenseService();
  final MemberService memberService = MemberService();
  final MarketScheduleService marketScheduleService = MarketScheduleService();
  final ContributionService contributionService = ContributionService();

  runApp(
    MultiProvider(
      providers: [
        // Services (singletons)
        Provider<AuthService>(create: (_) => authService),
        Provider<MemberService>(create: (_) => memberService),
        Provider<MealService>(create: (_) => mealService),
        Provider<ExpenseService>(create: (_) => expenseService),
        Provider<MarketScheduleService>(create: (_) => marketScheduleService),
        Provider<ContributionService>(create: (_) => contributionService),

        // Providers (depend on services)
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(
            context.read<AuthService>(),
          )..loadCurrentUser(), // Load user on app start
        ),
        ChangeNotifierProvider<MemberProvider>(
          create: (context) => MemberProvider(
            context.read<MemberService>(),
            context.read<AuthService>(), // MemberProvider now needs AuthService
          )..fetchAllMembers(), // Load members on app start
        ),
        ChangeNotifierProvider<MealProvider>(
          create: (context) => MealProvider(
            context.read<MealService>(),
          ),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (context) => ExpenseProvider(
            context.read<ExpenseService>(),
            context.read<ContributionService>(),
          ),
        ),
        ChangeNotifierProvider<MarketScheduleProvider>(
          create: (context) => MarketScheduleProvider(
            context.read<MarketScheduleService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: Colors.orangeAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMedium,
              horizontal: AppConstants.paddingMedium),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingMedium),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.registration: (context) => const RegistrationScreen(),
        AppRoutes.adminLogin: (context) => const AdminLoginScreen(),
        AppRoutes.memberLogin: (context) => const MemberLoginScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
        AppRoutes.managerDashboard: (context) => const ManagerDashboardScreen(),
        AppRoutes.memberDashboard: (context) => const MemberDashboardScreen(),
        AppRoutes.recordMeals: (context) => const RecordMealsScreen(),
        AppRoutes.recordExpense: (context) => const RecordExpenseScreen(),
        AppRoutes.manageContributions: (context) => const ManageContributionsScreen(),
        AppRoutes.marketSchedule: (context) => const MarketScheduleScreen(),
        AppRoutes.financialReport: (context) => const FinancialReportScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.personalMealHistory: (context) => const PersonalMealHistoryScreen(),
        AppRoutes.personalContributionHistory: (context) => const PersonalContributionHistoryScreen(),
        AppRoutes.personalExpenseHistory: (context) => const PersonalExpenseHistoryScreen(),
        AppRoutes.personalMarketDuty: (context) => const PersonalMarketDutyScreen(),
        AppRoutes.expenseAnalysis: (context) => const ExpenseAnalysisScreen(),
        // AppRoutes.dailyMealEntries: (context) => DailyMealEntriesScreen(), // Removed: This route is navigated via MaterialPageRoute
      },
    );
  }
}
