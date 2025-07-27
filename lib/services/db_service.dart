// # ✅ Handles SQLite DB init, insert, query
// File: lib/services/db_service.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/solar_data.dart';
import '../models/averaged_data.dart';
import '../enums/time_range.dart';
import 'prefs_service.dart';


import 'dart:math';


class DBService {
  static final DBService instance = DBService._internal();
  factory DBService() => instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = join(docsDir.path, 'solar_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE solar_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        solar_index REAL NOT NULL
      )
    ''');

    await db.execute('CREATE TABLE solar_avg_daily (hour INTEGER PRIMARY KEY, avg_index REAL, money_saved REAL)');
    await db.execute('CREATE TABLE solar_avg_weekly (weekday INTEGER PRIMARY KEY, avg_index REAL, money_saved REAL)');
    await db.execute('CREATE TABLE solar_avg_monthly (week INTEGER PRIMARY KEY, avg_index REAL, money_saved REAL)');
    await db.execute('CREATE TABLE solar_avg_yearly (month INTEGER PRIMARY KEY, avg_index REAL, money_saved REAL)');
  }

  Future<List<AveragedData>> getPrecomputedData(TimeRange range) async {
    final table = switch (range) {
      TimeRange.daily => 'solar_avg_daily',
      TimeRange.weekly => 'solar_avg_weekly',
      TimeRange.monthly => 'solar_avg_monthly',
      TimeRange.yearly => 'solar_avg_yearly',
    };

    final db = await this.db;
    final rows = await db.query(table);
    return rows.map((e) => AveragedData(
      e.values.first as int,
      e['avg_index'] as double,
      e['money_saved'] as double?,
    )).toList();
  }


  Future<void> insertSolarData(SolarData data) async {
    final database = await db;
    await database.insert(
      'solar_history',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SolarData>> getDataBetween(DateTime start, DateTime end) async {
    final database = await db;
    final result = await database.query(
      'solar_history',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );

    return result.map((row) => SolarData.fromMap(row)).toList();
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
  }

  // In DBService
  Future<void> insertDummyYearlyData() async {
    final database = await db;
    final batch = database.batch();

    final now = DateTime.now();
    final rand = Random();

    Map<int, List<double>> hourly = {};
    Map<int, List<double>> weekly = {};
    Map<int, List<double>> monthly = {};
    Map<int, List<double>> yearly = {};


    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final timestamp = date.millisecondsSinceEpoch;
      final solarIndex = 0.3 + rand.nextDouble() * 0.7;

      batch.insert('solar_history', {
        'timestamp': timestamp,
        'solar_index': solarIndex,
      });

      hourly.update(date.hour, (list) => list..add(solarIndex), ifAbsent: () => [solarIndex]);
      weekly.update(date.weekday, (list) => list..add(solarIndex), ifAbsent: () => [solarIndex]);
      monthly.update((date.day - 1) ~/ 7, (list) => list..add(solarIndex), ifAbsent: () => [solarIndex]);
      yearly.update(date.month, (list) => list..add(solarIndex), ifAbsent: () => [solarIndex]);
    }

    void insertAverages(String table, Map<int, List<double>> map) async {
      const ratePerKWh = 0.12;
      const hoursPerInterval = {
        'solar_avg_daily': 1,
        'solar_avg_weekly': 24,
        'solar_avg_monthly': 24 * 7,
        'solar_avg_yearly': 24 * 30,
      };

      final config = await PrefsService.instance.loadConfig();
      final basePower = config.projectedPowerWatts;

      map.forEach((key, values) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final avgPower = basePower * avg;
        final energyWh = avgPower * hoursPerInterval[table]!;
        final moneySaved = energyWh / 1000 * ratePerKWh;

        batch.insert(table, {
          table == 'solar_avg_monthly'
              ? 'week' : table == 'solar_avg_yearly'
                ? 'month' : table == 'solar_avg_weekly'
                  ? 'weekday' : 'hour': key,
          'avg_index': avg,
          'money_saved': moneySaved, // ✅ Now correctly defined

        });


      });


    }

    insertAverages('solar_avg_daily', hourly);
    insertAverages('solar_avg_weekly', weekly);
    insertAverages('solar_avg_monthly', monthly);
    insertAverages('solar_avg_yearly', yearly);

    await batch.commit(noResult: true);
    print("✅ Dummy seed data + precomputed averages inserted.");
  }

}
