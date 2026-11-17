import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/handover_models.dart';

class HandoverRepository {
  HandoverRepository({Database? testDb}) : _db = testDb;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'home_handover.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: createSchema,
    );
    return _db!;
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE viviendas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL DEFAULT '',
        emergency_contact TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE estancias (
        id TEXT PRIMARY KEY,
        home_id TEXT NOT NULL,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'home'
      )
    ''');
    await db.execute('''
      CREATE TABLE fichas (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL DEFAULT '',
        is_emergency INTEGER NOT NULL DEFAULT 0,
        location_hint TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE pasos (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        step_order INTEGER NOT NULL,
        instruction TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tareas (
        id TEXT PRIMARY KEY,
        home_id TEXT NOT NULL,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL DEFAULT 'Mensual',
        is_done INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<List<Vivienda>> listHomes() async {
    final db = await database;
    final rows = await db.query('viviendas', orderBy: 'created_at DESC');
    return rows.map(Vivienda.fromMap).toList();
  }

  Future<List<Estancia>> listRooms() async {
    final db = await database;
    final rows = await db.query('estancias');
    return rows.map(Estancia.fromMap).toList();
  }

  Future<List<Ficha>> listCards() async {
    final db = await database;
    final rows = await db.query('fichas');
    return rows.map(Ficha.fromMap).toList();
  }

  Future<List<Paso>> listSteps() async {
    final db = await database;
    final rows = await db.query('pasos', orderBy: 'step_order ASC');
    return rows.map(Paso.fromMap).toList();
  }

  Future<List<Tarea>> listTasks() async {
    final db = await database;
    final rows = await db.query('tareas');
    return rows.map(Tarea.fromMap).toList();
  }

  Future<void> upsertHome(Vivienda home) async {
    final db = await database;
    await db.insert('viviendas', home.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertRoom(Estancia room) async {
    final db = await database;
    await db.insert('estancias', room.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveCardWithSteps({
    required Ficha card,
    required List<Paso> steps,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('fichas', card.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('pasos', where: 'card_id = ?', whereArgs: [card.id]);
      for (final s in steps) {
        await txn.insert('pasos', s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> upsertTask(Tarea task) async {
    final db = await database;
    await db.insert('tareas', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

