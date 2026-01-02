import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Provider singleton per il database Drift
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider per controllare se il database esiste (utile per import all'avvio)
final databaseExistsProvider = FutureProvider<bool>((ref) async {
  final path = await AppDatabase.getDatabasePath();
  return File(path).exists();
});

/// Provider per il path del database
final databasePathProvider = FutureProvider<String>((ref) async {
  return AppDatabase.getDatabasePath();
});
