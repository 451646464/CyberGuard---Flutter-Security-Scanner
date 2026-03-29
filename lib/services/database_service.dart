import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_info.dart';
import '../models/security_scan.dart';
import '../models/file_info.dart';
import '../models/link_info.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('secyrity.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add installSource column to apps table
      try {
        await db.execute('ALTER TABLE apps ADD COLUMN installSource TEXT NOT NULL DEFAULT \'other\'');
      } catch (e) {
        debugPrint('Error adding installSource column: $e');
      }

      // Create files table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS files (
            path TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            size INTEGER NOT NULL,
            modifiedDate TEXT NOT NULL,
            securityLevel TEXT NOT NULL,
            threatType TEXT,
            details TEXT
          )
        ''');
      } catch (e) {
        debugPrint('Error creating files table: $e');
      }

      // Create links table
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS links (
            url TEXT PRIMARY KEY,
            securityLevel TEXT NOT NULL,
            threatType TEXT,
            details TEXT,
            scanDate TEXT NOT NULL,
            isValidUrl INTEGER NOT NULL
          )
        ''');
      } catch (e) {
        debugPrint('Error creating links table: $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Apps table
    await db.execute('''
      CREATE TABLE apps (
        packageName TEXT PRIMARY KEY,
        appName TEXT NOT NULL,
        version TEXT NOT NULL,
        versionCode INTEGER NOT NULL,
        securityLevel TEXT NOT NULL,
        dangerousPermissions TEXT,
        isSystemApp INTEGER NOT NULL,
        installDate TEXT NOT NULL,
        lastUpdateDate TEXT NOT NULL,
        installSource TEXT NOT NULL DEFAULT 'other'
      )
    ''');

    // Security scans table
    await db.execute('''
      CREATE TABLE security_scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        securityScore REAL NOT NULL,
        dangerousAppsCount INTEGER NOT NULL,
        networkStatus TEXT NOT NULL,
        isNetworkSecure INTEGER NOT NULL,
        androidVersion TEXT NOT NULL,
        isDeveloperModeEnabled INTEGER NOT NULL,
        scanDate TEXT NOT NULL,
        details TEXT
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Files table
    await db.execute('''
      CREATE TABLE files (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        size INTEGER NOT NULL,
        modifiedDate TEXT NOT NULL,
        securityLevel TEXT NOT NULL,
        threatType TEXT,
        details TEXT
      )
    ''');

    // Links table
    await db.execute('''
      CREATE TABLE links (
        url TEXT PRIMARY KEY,
        securityLevel TEXT NOT NULL,
        threatType TEXT,
        details TEXT,
        scanDate TEXT NOT NULL,
        isValidUrl INTEGER NOT NULL
      )
    ''');

    // Create default user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // In production, hash this password
    });
  }

  // User operations
  Future<bool> authenticateUser(String username, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error authenticating user: $e');
      return false;
    }
  }

  Future<bool> createUser(String username, String password) async {
    try {
      final db = await database;
      await db.insert('users', {
        'username': username,
        'password': password,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  // App operations
  Future<void> saveApps(List<AppInfo> apps) async {
    final db = await database;
    final batch = db.batch();
    
    for (var app in apps) {
      batch.insert(
        'apps',
        app.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<AppInfo>> getAllApps() async {
    final db = await database;
    final maps = await db.query('apps', orderBy: 'appName');
    return maps.map((map) => AppInfo.fromMap(map)).toList();
  }

  Future<List<AppInfo>> getDangerousApps() async {
    final db = await database;
    final maps = await db.query(
      'apps',
      where: 'securityLevel = ?',
      whereArgs: [AppSecurityLevel.dangerous.name],
      orderBy: 'appName',
    );
    return maps.map((map) => AppInfo.fromMap(map)).toList();
  }

  // Security scan operations
  Future<int> saveSecurityScan(SecurityScan scan) async {
    final db = await database;
    return await db.insert('security_scans', scan.toMap());
  }

  Future<List<SecurityScan>> getAllScans() async {
    final db = await database;
    final maps = await db.query(
      'security_scans',
      orderBy: 'scanDate DESC',
    );
    return maps.map((map) => SecurityScan.fromMap(map)).toList();
  }

  Future<SecurityScan?> getLatestScan() async {
    final db = await database;
    final maps = await db.query(
      'security_scans',
      orderBy: 'scanDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SecurityScan.fromMap(maps.first);
  }

  Future<List<SecurityScan>> getScansByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      'security_scans',
      where: 'scanDate >= ? AND scanDate <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'scanDate DESC',
    );
    return maps.map((map) => SecurityScan.fromMap(map)).toList();
  }

  // Notification operations
  Future<int> saveNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final db = await database;
    return await db.insert('notifications', {
      'title': title,
      'message': message,
      'type': type,
      'isRead': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
    );
  }

  Future<void> markNotificationAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUnreadNotificationsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE isRead = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // File operations
  Future<void> saveFiles(List<FileInfo> files) async {
    final db = await database;
    final batch = db.batch();
    
    for (var file in files) {
      batch.insert(
        'files',
        file.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<FileInfo>> getAllFiles() async {
    final db = await database;
    final maps = await db.query('files', orderBy: 'modifiedDate DESC');
    return maps.map((map) => FileInfo.fromMap(map)).toList();
  }

  Future<List<FileInfo>> getDangerousFiles() async {
    final db = await database;
    final maps = await db.query(
      'files',
      where: 'securityLevel = ?',
      whereArgs: [FileSecurityLevel.dangerous.name],
      orderBy: 'modifiedDate DESC',
    );
    return maps.map((map) => FileInfo.fromMap(map)).toList();
  }

  Future<List<FileInfo>> getSuspiciousFiles() async {
    final db = await database;
    final maps = await db.query(
      'files',
      where: 'securityLevel = ?',
      whereArgs: [FileSecurityLevel.suspicious.name],
      orderBy: 'modifiedDate DESC',
    );
    return maps.map((map) => FileInfo.fromMap(map)).toList();
  }

  // Link operations
  Future<void> saveLink(LinkInfo link) async {
    final db = await database;
    await db.insert(
      'links',
      link.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LinkInfo>> getAllLinks() async {
    final db = await database;
    final maps = await db.query('links', orderBy: 'scanDate DESC');
    return maps.map((map) => LinkInfo.fromMap(map)).toList();
  }

  Future<List<LinkInfo>> getDangerousLinks() async {
    final db = await database;
    final maps = await db.query(
      'links',
      where: 'securityLevel = ?',
      whereArgs: [LinkSecurityLevel.dangerous.name],
      orderBy: 'scanDate DESC',
    );
    return maps.map((map) => LinkInfo.fromMap(map)).toList();
  }

  Future<void> initDatabase() async {
    try {
      // Initialize database by accessing it
      final db = await database;
      
      // Ensure default user exists
      final existingUser = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );
      
      if (existingUser.isEmpty) {
        await db.insert('users', {
          'username': 'admin',
          'password': 'admin123',
        });
        debugPrint('Default user created');
      } else {
        debugPrint('Default user already exists');
      }
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
}

