// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mess_meal_management_app/utils/app_constants.dart';
import 'package:mess_meal_management_app/utils/date_helpers.dart'; // Import DateHelpers

/// A helper class to manage database operations using sqflite.
class DatabaseHelper {
  static Database? _database; // Private instance of the database
  static final DatabaseHelper _instance = DatabaseHelper._internal(); // Singleton instance

  // Private constructor for the singleton pattern
  DatabaseHelper._internal();

  /// Factory constructor to return the singleton instance.
  factory DatabaseHelper() => _instance;

  /// Getter for the database instance. Initializes it if it's null.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database.
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database tables.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers}(
        ${AppConstants.columnUserId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnUsername} TEXT UNIQUE NOT NULL,
        ${AppConstants.columnPasswordHash} TEXT NOT NULL,
        ${AppConstants.columnUserRole} TEXT NOT NULL,
        ${AppConstants.columnIsActive} INTEGER NOT NULL DEFAULT 1,
        ${AppConstants.columnMemberId} INTEGER UNIQUE,
        FOREIGN KEY (${AppConstants.columnMemberId}) REFERENCES ${AppConstants.tableMembers}(${AppConstants.columnMemberIdPk}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMembers}(
        ${AppConstants.columnMemberIdPk} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnMemberName} TEXT NOT NULL,
        ${AppConstants.columnMemberEmail} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMealEntries}(
        ${AppConstants.columnMealEntryId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnMealMemberId} INTEGER NOT NULL,
        ${AppConstants.columnMealDate} TEXT NOT NULL, -- Store as TEXT (YYYY-MM-DD)
        ${AppConstants.columnBreakfastMeals} REAL NOT NULL,
        ${AppConstants.columnLunchMeals} REAL NOT NULL,
        ${AppConstants.columnDinnerMeals} REAL NOT NULL,
        ${AppConstants.columnGuestMeals} REAL NOT NULL,
        FOREIGN KEY (${AppConstants.columnMealMemberId}) REFERENCES ${AppConstants.tableMembers}(${AppConstants.columnMemberIdPk}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableExpenses}(
        ${AppConstants.columnExpenseId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnExpenseDate} TEXT NOT NULL, -- Store as TEXT (YYYY-MM-DD)
        ${AppConstants.columnExpenseAmount} REAL NOT NULL,
        ${AppConstants.columnExpenseDescription} TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableContributions}(
        ${AppConstants.columnContributionId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnContributionMemberId} INTEGER NOT NULL,
        ${AppConstants.columnContributionDate} TEXT NOT NULL, -- Store as TEXT (YYYY-MM-DD)
        ${AppConstants.columnContributionAmount} REAL NOT NULL,
        FOREIGN KEY (${AppConstants.columnContributionMemberId}) REFERENCES ${AppConstants.tableMembers}(${AppConstants.columnMemberIdPk}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableMarketSchedules}(
        ${AppConstants.columnMarketScheduleId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.columnMarketMemberId} INTEGER NOT NULL,
        ${AppConstants.columnMarketScheduleDate} TEXT NOT NULL, -- Store as TEXT (YYYY-MM-DD)
        ${AppConstants.columnMarketDutyTitle} TEXT NOT NULL,
        ${AppConstants.columnMarketDescription} TEXT,
        FOREIGN KEY (${AppConstants.columnMarketMemberId}) REFERENCES ${AppConstants.tableMembers}(${AppConstants.columnMemberIdPk}) ON DELETE CASCADE
      )
    ''');
  }

  /// Handles database upgrades (e.g., adding new tables or columns).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example: If you need to add a new column in a future version
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ${AppConstants.tableUsers} ADD COLUMN new_column TEXT;');
    // }
  }

  /// Inserts a row into a table.
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    // Ensure dates are formatted as YYYY-MM-DD before inserting
    final Map<String, dynamic> dataToInsert = Map.from(data);
    if (dataToInsert.containsKey(AppConstants.columnMealDate) && dataToInsert[AppConstants.columnMealDate] is String) {
      // If it's already a string, ensure it's in YYYY-MM-DD format
      dataToInsert[AppConstants.columnMealDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToInsert[AppConstants.columnMealDate]));
    } else if (dataToInsert.containsKey(AppConstants.columnMealDate) && dataToInsert[AppConstants.columnMealDate] is DateTime) {
      dataToInsert[AppConstants.columnMealDate] = DateHelpers.formatDateToYYYYMMDD(dataToInsert[AppConstants.columnMealDate]);
    }
    // Apply similar logic for other date columns if they exist in the map
    if (dataToInsert.containsKey(AppConstants.columnExpenseDate) && dataToInsert[AppConstants.columnExpenseDate] is String) {
      dataToInsert[AppConstants.columnExpenseDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToInsert[AppConstants.columnExpenseDate]));
    } else if (dataToInsert.containsKey(AppConstants.columnExpenseDate) && dataToInsert[AppConstants.columnExpenseDate] is DateTime) {
      dataToInsert[AppConstants.columnExpenseDate] = DateHelpers.formatDateToYYYYMMDD(dataToInsert[AppConstants.columnExpenseDate]);
    }
    if (dataToInsert.containsKey(AppConstants.columnContributionDate) && dataToInsert[AppConstants.columnContributionDate] is String) {
      dataToInsert[AppConstants.columnContributionDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToInsert[AppConstants.columnContributionDate]));
    } else if (dataToInsert.containsKey(AppConstants.columnContributionDate) && dataToInsert[AppConstants.columnContributionDate] is DateTime) {
      dataToInsert[AppConstants.columnContributionDate] = DateHelpers.formatDateToYYYYMMDD(dataToInsert[AppConstants.columnContributionDate]);
    }
    if (dataToInsert.containsKey(AppConstants.columnMarketScheduleDate) && dataToInsert[AppConstants.columnMarketScheduleDate] is String) {
      dataToInsert[AppConstants.columnMarketScheduleDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToInsert[AppConstants.columnMarketScheduleDate]));
    } else if (dataToInsert.containsKey(AppConstants.columnMarketScheduleDate) && dataToInsert[AppConstants.columnMarketScheduleDate] is DateTime) {
      dataToInsert[AppConstants.columnMarketScheduleDate] = DateHelpers.formatDateToYYYYMMDD(dataToInsert[AppConstants.columnMarketScheduleDate]);
    }

    return await db.insert(table, dataToInsert, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Queries all rows from a table.
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  /// Queries rows from a table based on a WHERE clause.
  Future<List<Map<String, dynamic>>> query(
      String table, {
        bool? distinct,
        List<String>? columns,
        String? where,
        List<Object?>? whereArgs,
        String? groupBy,
        String? having,
        String? orderBy,
        int? limit,
        int? offset,
      }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Updates a row in a table.
  Future<int> update(String table, Map<String, dynamic> data, String where, List<Object?> whereArgs) async {
    final db = await database;
    // Ensure dates are formatted as YYYY-MM-DD before updating
    final Map<String, dynamic> dataToUpdate = Map.from(data);
    if (dataToUpdate.containsKey(AppConstants.columnMealDate) && dataToUpdate[AppConstants.columnMealDate] is String) {
      dataToUpdate[AppConstants.columnMealDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToUpdate[AppConstants.columnMealDate]));
    } else if (dataToUpdate.containsKey(AppConstants.columnMealDate) && dataToUpdate[AppConstants.columnMealDate] is DateTime) {
      dataToUpdate[AppConstants.columnMealDate] = DateHelpers.formatDateToYYYYMMDD(dataToUpdate[AppConstants.columnMealDate]);
    }
    // Apply similar logic for other date columns if they exist in the map
    if (dataToUpdate.containsKey(AppConstants.columnExpenseDate) && dataToUpdate[AppConstants.columnExpenseDate] is String) {
      dataToUpdate[AppConstants.columnExpenseDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToUpdate[AppConstants.columnExpenseDate]));
    } else if (dataToUpdate.containsKey(AppConstants.columnExpenseDate) && dataToUpdate[AppConstants.columnExpenseDate] is DateTime) {
      dataToUpdate[AppConstants.columnExpenseDate] = DateHelpers.formatDateToYYYYMMDD(dataToUpdate[AppConstants.columnExpenseDate]);
    }
    if (dataToUpdate.containsKey(AppConstants.columnContributionDate) && dataToUpdate[AppConstants.columnContributionDate] is String) {
      dataToUpdate[AppConstants.columnContributionDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToUpdate[AppConstants.columnContributionDate]));
    } else if (dataToUpdate.containsKey(AppConstants.columnContributionDate) && dataToUpdate[AppConstants.columnContributionDate] is DateTime) {
      dataToUpdate[AppConstants.columnContributionDate] = DateHelpers.formatDateToYYYYMMDD(dataToUpdate[AppConstants.columnContributionDate]);
    }
    if (dataToUpdate.containsKey(AppConstants.columnMarketScheduleDate) && dataToUpdate[AppConstants.columnMarketScheduleDate] is String) {
      dataToUpdate[AppConstants.columnMarketScheduleDate] = DateHelpers.formatDateToYYYYMMDD(DateTime.parse(dataToUpdate[AppConstants.columnMarketScheduleDate]));
    } else if (dataToUpdate.containsKey(AppConstants.columnMarketScheduleDate) && dataToUpdate[AppConstants.columnMarketScheduleDate] is DateTime) {
      dataToUpdate[AppConstants.columnMarketScheduleDate] = DateHelpers.formatDateToYYYYMMDD(dataToUpdate[AppConstants.columnMarketScheduleDate]);
    }

    return await db.update(table, dataToUpdate, where: where, whereArgs: whereArgs);
  }

  /// Deletes rows from a table.
  Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Executes a raw SQL query.
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Resets the entire database by deleting and recreating it.
  Future<void> resetDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);
    await deleteDatabase(path);
    _database = null; // Clear the singleton instance
    await database; // Re-initialize the database
  }
}
