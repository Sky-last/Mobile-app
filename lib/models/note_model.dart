class NoteModel {
  final int? noteId;
  final String noteTitle;
  final String noteContent;
  final String createdAt;
  final String? category; // NEW: Kategori note
  final String? categoryColor; // NEW: Warna kategori (hex string)
  final int isPinned; // NEW: 0 = tidak pin, 1 = pin
  final String? reminderTime; // NEW: Waktu reminder (ISO8601 string)

  NoteModel({
    this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.createdAt,
    this.category,
    this.categoryColor,
    this.isPinned = 0,
    this.reminderTime,
  });

  factory NoteModel.fromMap(Map<String, dynamic> json) => NoteModel(
        noteId: json['noteId'],
        noteTitle: json['noteTitle'],
        noteContent: json['noteContent'],
        createdAt: json['createdAt'],
        category: json['category'],
        categoryColor: json['categoryColor'],
        isPinned: json['isPinned'] ?? 0,
        reminderTime: json['reminderTime'],
      );

  Map<String, dynamic> toMap() => {
        'noteId': noteId,
        'noteTitle': noteTitle,
        'noteContent': noteContent,
        'createdAt': createdAt,
        'category': category,
        'categoryColor': categoryColor,
        'isPinned': isPinned,
        'reminderTime': reminderTime,
      };

  // Helper method untuk copy note dengan perubahan
  NoteModel copyWith({
    int? noteId,
    String? noteTitle,
    String? noteContent,
    String? createdAt,
    String? category,
    String? categoryColor,
    int? isPinned,
    String? reminderTime,
  }) {
    return NoteModel(
      noteId: noteId ?? this.noteId,
      noteTitle: noteTitle ?? this.noteTitle,
      noteContent: noteContent ?? this.noteContent,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      isPinned: isPinned ?? this.isPinned,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}