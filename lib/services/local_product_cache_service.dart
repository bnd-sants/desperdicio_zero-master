import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:desperdicio_zero/models/product_model.dart';

class LocalProductCacheService {
  LocalProductCacheService._internal();

  static final LocalProductCacheService _instance = LocalProductCacheService._internal();
  factory LocalProductCacheService() => _instance;

  static Database? _database;
  static bool _factoryInitialized = false;
  static const String _tableName = 'cached_products';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  void _ensureDatabaseFactory() {
    if (_factoryInitialized) return;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _factoryInitialized = true;
  }

  Future<Database> _initDatabase() async {
    _ensureDatabaseFactory();
    final path = join(await getDatabasesPath(), 'products_cache_v1.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            expiration_date TEXT,
            type TEXT,
            brand TEXT,
            barcode TEXT,
            store TEXT,
            price REAL,
            is_consumed INTEGER NOT NULL DEFAULT 0,
            purchase_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            calories INTEGER,
            carbs REAL,
            protein REAL,
            fat REAL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_products_user_id ON $_tableName(user_id)');
      },
    );
  }

  Future<void> saveProducts(String userId, List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    batch.delete(_tableName, where: 'user_id = ?', whereArgs: [userId]);

    for (final product in products) {
      batch.insert(
        _tableName,
        {
          ...product.toJson(),
          'is_consumed': product.isConsumed ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Product>> getProducts(String userId) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'expiration_date ASC',
    );

    return rows
        .map(
          (row) => Product.fromJson({
            ...row,
            'is_consumed': (row['is_consumed'] as int? ?? 0) == 1,
          }),
        )
        .toList();
  }
}
