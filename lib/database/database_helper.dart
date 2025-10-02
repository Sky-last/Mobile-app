import 'package:notes_app_5sia1/models/note_model.dart';
import 'package:notes_app_5sia1/models/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Configuration variables
  static Database? _database;
  final String databaseName = "note_5sia3.db";
  final int databaseVersion = 2; // UPDATE VERSION untuk migration

  // Create user table
  final String createUserTable = ''' 
  CREATE TABLE users ( 
    userId INTEGER PRIMARY KEY AUTOINCREMENT, 
    userName TEXT UNIQUE NOT NULL, 
    userPassword TEXT NOT NULL 
  ) 
  ''';

  // create note table (UPDATED dengan kolom baru)
  final String createNoteTable = ''' 
  CREATE TABLE notes ( 
    noteId INTEGER PRIMARY KEY AUTOINCREMENT, 
    noteTitle TEXT NOT NULL, 
    noteContent TEXT NOT NULL, 
    createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
    category TEXT,
    categoryColor TEXT,
    isPinned INTEGER DEFAULT 0,
    reminderTime TEXT
  ) 
  ''';

  // Initialize the database
  Future<Database> initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    return openDatabase(
      path,
      version: databaseVersion,
      onCreate: (db, version) async {
        await db.execute(createUserTable);
        await db.execute(createNoteTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration: tambah kolom baru ke tabel notes
          await db.execute('ALTER TABLE notes ADD COLUMN category TEXT');
          await db.execute('ALTER TABLE notes ADD COLUMN categoryColor TEXT');
          await db.execute('ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE notes ADD COLUMN reminderTime TEXT');
        }
      },
    );
  }

  // Getter database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<bool> login(UserModel user) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'userName = ? AND userPassword = ?',
      whereArgs: [user.userName, user.userPassword],
    );

    return result.isNotEmpty;
  }

  //  fungsi created account
  Future<int> createAccount(UserModel user) async {
    final Database db = await database;
    return db.insert('users', user.toMap());
  }

  // Create note method
  Future<int> createNote(NoteModel note) async {
    final Database db = await database;
    return db.insert('notes', note.toMap());
  }

  // Get notes method (dengan sorting: pinned notes di atas)
  Future<List<NoteModel>> getNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      orderBy: 'isPinned DESC, createdAt DESC', // Pin notes muncul duluan
    );
    return result.map((e) => NoteModel.fromMap(e)).toList();
  }

  // Update note method (UPDATED untuk support semua field)
  Future<int> updateNote(NoteModel note) async {
    final Database db = await database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'noteId = ?',
      whereArgs: [note.noteId],
    );
  }

  // Delete notes method
  Future<int> deleteNote(int id) async {
    final Database db = await database;
    return db.delete('notes', where: 'noteId = ?', whereArgs: [id]);
  }

  // search notes method
  Future<List<NoteModel>> searchNotes(String keyword) async {
    final Database db = await database;

    final List<Map<String, Object?>> result = await db.query(
      'notes',
      where: 'LOWER(noteTitle) LIKE ? OR LOWER(noteContent) LIKE?',
      whereArgs: ['%${keyword.toLowerCase()}%', '%${keyword.toLowerCase()}%'],
      orderBy: 'isPinned DESC, createdAt DESC',
    );

    return result.map((map) => NoteModel.fromMap(map)).toList();
  }

  // NEW: Toggle pin status
  Future<int> togglePinNote(int noteId, int currentPinStatus) async {
    final Database db = await database;
    return db.update(
      'notes',
      {'isPinned': currentPinStatus == 1 ? 0 : 1},
      where: 'noteId = ?',
      whereArgs: [noteId],
    );
  }

  // NEW: Get notes by category
  Future<List<NoteModel>> getNotesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return result.map((e) => NoteModel.fromMap(e)).toList();
  }

  // NEW: Get all unique categories
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM notes WHERE category IS NOT NULL ORDER BY category',
    );
    return result.map((e) => e['category'] as String).toList();
  }

  // NEW: Get notes with reminders
  Future<List<NoteModel>> getNotesWithReminders() async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'reminderTime IS NOT NULL',
      orderBy: 'reminderTime ASC',
    );
    return result.map((e) => NoteModel.fromMap(e)).toList();
  }
}