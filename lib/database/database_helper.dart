import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // تفعيل sqflite_common_ffi على أنظمة سطح المكتب
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbDir = join(appDocDir.path, 'Aqsati');
    await Directory(dbDir).create(recursive: true);
    final String path = join(dbDir, 'aqsati.db');

    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        principal_amount REAL NOT NULL,
        profit_amount REAL NOT NULL,
        months INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        distribution_mode TEXT NOT NULL DEFAULT 'auto',
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        month_index INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        scheduled_profit REAL NOT NULL,
        payment_amount REAL NOT NULL DEFAULT 0,
        payment_date TEXT,
        notes TEXT,
        FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_loans_customer ON loans(customer_id)');
    await db.execute('CREATE INDEX idx_installments_loan ON installments(loan_id)');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
