// lib/screens/manager/manager_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mess_meal_management_app/models/monthly_summary.dart';
import 'package:mess_meal_management_app/models/member.dart';
import 'package:mess_meal_management_app/providers/user_provider.dart';
import 'package:mess_meal_management_app/providers/meal_provider.dart';
import 'package:mess_meal_management_app/providers/expense_provider.dart';
import 'package:mess_meal_management_app/providers/market_schedule_provider.dart';
import 'package:mess_meal_management_app/providers/member_provider.dart';
import 'package:mess_meal_management_app/routes.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart';
import 'package:mess_meal_management_app/widgets/dashboard_card.dart';

/// Manager dashboard displaying overall mess summaries and navigation to management features.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final DateTime _currentMonth = DateTime.now();
  bool _isLoading = false;
  MonthlySummary? _overallMonthlySummary; // Renamed for clarity (overall mess summary)
  MonthlySummary? _personalMonthlySummary; // Added for manager's personal summary

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Fetches all necessary data for the manager dashboard.
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context, listen: false);

      // --- Fetch Overall Mess Data ---
      await mealProvider.calculateMonthlyMeals(_currentMonth.month, _currentMonth.year);
      await expenseProvider.calculateMonthlyFinancials(_currentMonth.month, _currentMonth.year);
      await expenseProvider.calculatePredictedNextMonthExpenses(); // New: Calculate predicted expenses for dashboard card
      await memberProvider.fetchAllMembers(); // Fetch all members for balance calculation
      await marketScheduleProvider.fetchUpcomingMarketSchedules(); // Fetch for display

      final List<Member> allMembers = memberProvider.members;
      final double totalMessMeals = mealProvider.monthlyMessMeals;
      final double totalMessExpenses = expenseProvider.monthlyTotalExpenses;
      final double totalMessContributions = expenseProvider.monthlyTotalContributions;

      double mealRate = 0.0;
      if (totalMessMeals > 0) {
        mealRate = totalMessExpenses / totalMessMeals;
      }

      List<MemberBalance> overallMemberBalances = [];
      for (Member member in allMembers) {
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
            member.id!, _currentMonth.month, _currentMonth.year);
        final personalContributions = await expenseProvider.fetchContributionsByMember(member.id!)
            .then((list) => list.where((c) => DateHelpers.isSameDay(DateHelpers.firstDayOfMonth(_currentMonth), DateHelpers.firstDayOfMonth(c.contributionDate))).fold(0.0, (sum, item) => sum + item.amount));

        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        overallMemberBalances.add(MemberBalance(
          memberId: member.id!,
          memberName: member.name,
          personalMeals: personalMeals,
          personalContributions: personalContributions,
          shareOfExpenses: shareOfExpenses,
          balance: balance,
        ));
      }

      // Set overall mess summary
      _overallMonthlySummary = MonthlySummary(
        month: _currentMonth.month,
        year: _currentMonth.year,
        totalMessMeals: totalMessMeals,
        totalMessExpenses: totalMessExpenses,
        totalMessContributions: totalMessContributions,
        mealRate: mealRate,
        memberBalances: overallMemberBalances,
      );

      // --- Fetch Personal Manager Data ---
      final int? currentManagerMemberId = userProvider.currentMember?.id;
      final String? currentManagerMemberName = userProvider.currentMember?.name;

      if (currentManagerMemberId != null && currentManagerMemberName != null) {
        final personalMeals = await mealProvider.getMonthlyTotalMealsForMember(
            currentManagerMemberId, _currentMonth.month, _currentMonth.year);
        final personalContributionsList = await expenseProvider.fetchContributionsByMember(currentManagerMemberId);
        final personalContributions = personalContributionsList
            .where((c) => DateHelpers.isSameDay(DateHelpers.firstDayOfMonth(_currentMonth), DateHelpers.firstDayOfMonth(c.contributionDate)))
            .fold(0.0, (sum, item) => sum + item.amount);

        final shareOfExpenses = personalMeals * mealRate;
        final balance = personalContributions - shareOfExpenses;

        _personalMonthlySummary = MonthlySummary(
          month: _currentMonth.month,
          year: _currentMonth.year,
          totalMessMeals: totalMessMeals, // Overall mess total (can be reused)
          totalMessExpenses: totalMessExpenses, // Overall mess total (can be reused)
          totalMessContributions: totalMessContributions, // Overall mess total (can be reused)
          mealRate: mealRate,
          memberBalances: [
            MemberBalance(
              memberId: currentManagerMemberId,
              memberName: currentManagerMemberName,
              personalMeals: personalMeals,
              personalContributions: personalContributions,
              shareOfExpenses: shareOfExpenses,
              balance: balance,
            )
          ],
        );
      }
    } catch (e) {
      print('Error fetching manager dashboard data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handles user logout.
  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();
    Navigator.of(context).pushReplacementNamed(AppRoutes.memberLogin);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final marketScheduleProvider = Provider.of<MarketScheduleProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context); // Listen to ExpenseProvider for prediction

    final DateTime nextMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: AppConstants.logoutButton,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${userProvider.currentMember?.name ?? userProvider.currentUser?.username ?? 'Manager'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // --- Your Monthly Summary (Personal for Manager) ---
            Text(
              'Your Monthly Summary (${DateHelpers.formatMonthYear(_currentMonth)})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (_personalMonthlySummary != null && _personalMonthlySummary!.memberBalances.isNotEmpty)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.paddingMedium,
                mainAxisSpacing: AppConstants.paddingMedium,
                children: [
                  DashboardCard(
                    title: 'Your Meals',
                    value: _personalMonthlySummary!.memberBalances.first.personalMeals.toStringAsFixed(0),
                    icon: Icons.restaurant,
                    color: Colors.blue.shade50,
                  ),
                  DashboardCard(
                    title: 'Your Contributions',
                    value: '৳${_personalMonthlySummary!.memberBalances.first.personalContributions.toStringAsFixed(2)}',
                    icon: Icons.payments,
                    color: Colors.green.shade50,
                  ),
                  DashboardCard(
                    title: 'Your Share of Expenses',
                    value: '৳${_personalMonthlySummary!.memberBalances.first.shareOfExpenses.toStringAsFixed(2)}',
                    icon: Icons.shopping_cart,
                    color: Colors.red.shade50,
                  ),
                  DashboardCard(
                    title: 'Your Balance',
                    value: _personalMonthlySummary!.memberBalances.first.balance >= 0
                        ? 'Owed: ৳${_personalMonthlySummary!.memberBalances.first.balance.toStringAsFixed(2)}'
                        : 'Owes: ৳${(_personalMonthlySummary!.memberBalances.first.balance * -1).toStringAsFixed(2)}',
                    icon: Icons.account_balance,
                    color: _personalMonthlySummary!.memberBalances.first.balance >= 0 ? Colors.lightGreen.shade50 : Colors.orange.shade50,
                  ),
                ],
              )
            else
              const Center(child: Text('No personal financial data available for this month.')),
            const SizedBox(height: AppConstants.paddingLarge),

            // --- Overall Mess Status ---
            Text(
              'Overall Mess Status (${DateHelpers.formatMonthYear(_currentMonth)})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (_overallMonthlySummary != null)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.paddingMedium,
                mainAxisSpacing: AppConstants.paddingMedium,
                children: [
                  DashboardCard(
                    title: 'Total Mess Meals',
                    value: _overallMonthlySummary!.totalMessMeals.toStringAsFixed(0),
                    icon: Icons.fastfood,
                    color: Colors.purple.shade50,
                  ),
                  DashboardCard(
                    title: 'Total Mess Expenses',
                    value: '৳${_overallMonthlySummary!.totalMessExpenses.toStringAsFixed(2)}',
                    icon: Icons.shopping_basket,
                    color: Colors.red.shade50,
                  ),
                  DashboardCard(
                    title: 'Total Mess Contributions',
                    value: '৳${_overallMonthlySummary!.totalMessContributions.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.teal.shade50,
                  ),
                  DashboardCard(
                    title: 'Current Mess Balance',
                    value: '৳${expenseProvider.currentMessBalance.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    color: expenseProvider.currentMessBalance >= 0 ? Colors.lightGreen.shade50 : Colors.orange.shade50,
                  ),
                  DashboardCard(
                    title: 'Current Meal Rate',
                    value: '৳${_overallMonthlySummary!.mealRate.toStringAsFixed(2)} / meal',
                    icon: Icons.calculate,
                    color: Colors.cyan.shade50,
                  ),
                  // New: Predicted Expenses Card
                  DashboardCard(
                    title: '${AppConstants.predictedExpenses} (${DateHelpers.formatMonthYear(nextMonth)})',
                    value: '৳${expenseProvider.predictedNextMonthExpenses.toStringAsFixed(2)}',
                    icon: Icons.lightbulb_outline,
                    color: Colors.amber.shade50,
                  ),
                ],
              )
            else
              const Center(child: Text('No overall mess financial data available for this month.')),
            const SizedBox(height: AppConstants.paddingLarge),

            // Upcoming Market Duties (Manager View)
            Text(
              'Upcoming Market Duties',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            marketScheduleProvider.upcomingMarketSchedules.isEmpty
                ? const Center(child: Text('No upcoming market duties scheduled.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: marketScheduleProvider.upcomingMarketSchedules.length,
              itemBuilder: (context, index) {
                final duty = marketScheduleProvider.upcomingMarketSchedules[index];
                final assignedMember = Provider.of<MemberProvider>(context, listen: false).getMemberById(duty.memberId);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                    title: Text('${duty.dutyTitle} - ${assignedMember?.name ?? 'Unknown Member'}'), // Display Duty Title
                    subtitle: Text('Date: ${DateHelpers.formatDate(duty.scheduleDate)}\nDescription: ${duty.description}'),
                    isThreeLine: true, // Allow subtitle to take more lines
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Management Features Navigation
            Text(
              'Management Features',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Column(
              children: [
                _buildDashboardButton(
                  context,
                  AppConstants.recordMeals,
                  Icons.restaurant_menu,
                  AppRoutes.recordMeals,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.recordExpense,
                  Icons.shopping_basket,
                  AppRoutes.recordExpense,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.manageContributions,
                  Icons.payments,
                  AppRoutes.manageContributions,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.marketSchedule,
                  Icons.calendar_month,
                  AppRoutes.marketSchedule,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.financialReport,
                  Icons.assignment,
                  AppRoutes.financialReport,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.expenseAnalysis, // New button for Expense Analysis
                  Icons.analytics,
                  AppRoutes.expenseAnalysis,
                ),
                _buildDashboardButton(
                  context,
                  AppConstants.profile,
                  Icons.person,
                  AppRoutes.profile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context, String title, IconData icon, String routeName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(routeName);
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Icon(icon, size: 30, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppConstants.paddingMedium),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
