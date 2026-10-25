import 'dart:io' if (dart.library.html) 'web_platform_stub.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data/app_state.dart';
import 'data/database_helper.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop/web SQLite support BEFORE any database access
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    // Open and inspect the same database used by registration and login.
    final db = await DatabaseHelper.instance.database;
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );
    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );
    final sessionRow = await db.rawQuery('SELECT userId FROM session LIMIT 1');
    debugPrint('DATABASE SUCCESS: ${db.path}');
    debugPrint('DATABASE PRODUCTS: ${productCount ?? 0}');
    debugPrint('DATABASE USERS: ${userCount ?? 0}');
    debugPrint(
      'DATABASE SESSION: ${sessionRow.isEmpty ? 'none' : sessionRow.first['userId']}',
    );

    // Restore a previously signed-in session (if any).
    await AppState.instance.restoreUser();
  } catch (e) {
    debugPrint('DATABASE ERROR: $e');
  }

  runApp(const ReLoopApp());
}

class ReLoopApp extends StatelessWidget {
  const ReLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReLoop Swap',
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}