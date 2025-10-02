import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app_5sia1/auth/login_screen.dart';
import 'package:notes_app_5sia1/database/database_helper.dart';
import 'package:notes_app_5sia1/models/note_model.dart';
import 'package:notes_app_5sia1/notes/create_note_screen.dart';
import 'package:notes_app_5sia1/notes/update_note_screen.dart';
import 'package:notes_app_5sia1/providers/theme_provider.dart';
import 'package:notes_app_5sia1/widgets/note_card.dart';
import 'package:notes_app_5sia1/widgets/empty_state.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  late DatabaseHelper handler;
  late Future<List<NoteModel>> notes;
  late AnimationController _animationController;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  String? _selectedCategory;
  String _sortBy = 'date_desc'; // date_desc, date_asc, title_asc, title_desc

  @override
  void initState() {
    super.initState();
    handler = DatabaseHelper();
    notes = handler.getNotes();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void refreshNotes() {
    setState(() {
      if (_searchKeyword.isNotEmpty) {
        notes = handler.searchNotes(_searchKeyword);
      } else if (_selectedCategory != null) {
        notes = handler.getNotesByCategory(_selectedCategory!);
      } else {
        notes = handler.getNotes();
      }
    });
  }

  List<NoteModel> sortNotes(List<NoteModel> notesList) {
    switch (_sortBy) {
      case 'date_asc':
        notesList.sort((a, b) => DateTime.parse(a.createdAt)
            .compareTo(DateTime.parse(b.createdAt)));
        break;
      case 'title_asc':
        notesList.sort((a, b) => a.noteTitle.compareTo(b.noteTitle));
        break;
      case 'title_desc':
        notesList.sort((a, b) => b.noteTitle.compareTo(a.noteTitle));
        break;
      case 'date_desc':
      default:
        notesList.sort((a, b) => DateTime.parse(b.createdAt)
            .compareTo(DateTime.parse(a.createdAt)));
    }
    
    // Keep pinned notes at top
    final pinned = notesList.where((n) => n.isPinned == 1).toList();
    final unpinned = notesList.where((n) => n.isPinned != 1).toList();
    
    return [...pinned, ...unpinned];
  }

  void showDeleteDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Note'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${note.noteTitle}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              int result = await handler.deleteNote(note.noteId!);
              if (!mounted) return;

              if (result > 0) {
                refreshNotes();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Note deleted successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.teal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> togglePin(NoteModel note) async {
    int result = await handler.togglePinNote(note.noteId!, note.isPinned);
    
    if (!mounted) return;

    if (result > 0) {
      refreshNotes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                note.isPinned == 1 ? Icons.push_pin_outlined : Icons.push_pin,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Text(note.isPinned == 1 ? 'Note unpinned' : 'Note pinned'),
            ],
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSortOption('Newest First', 'date_desc', Icons.arrow_downward),
            _buildSortOption('Oldest First', 'date_asc', Icons.arrow_upward),
            _buildSortOption('Title (A-Z)', 'title_asc', Icons.sort_by_alpha),
            _buildSortOption('Title (Z-A)', 'title_desc', Icons.sort_by_alpha),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _sortBy,
      onChanged: (val) {
        setState(() {
          _sortBy = val!;
        });
        Navigator.pop(context);
        refreshNotes();
      },
      title: Text(label),
      secondary: Icon(icon),
      activeColor: Colors.teal,
    );
  }

  void showCategoryFilter() async {
    final categories = await handler.getAllCategories();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.all_inclusive, color: Colors.teal),
              title: Text('All Notes'),
              trailing: _selectedCategory == null
                  ? Icon(Icons.check, color: Colors.teal)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                  refreshNotes();
                });
                Navigator.pop(context);
              },
            ),
            if (categories.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No categories yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...categories.map((category) => ListTile(
                leading: Icon(Icons.label, color: Colors.teal),
                title: Text(category),
                trailing: _selectedCategory == category
                    ? Icon(Icons.check, color: Colors.teal)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    refreshNotes();
                  });
                  Navigator.pop(context);
                },
              )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? Color(0xFF121212)
          : Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        title: Text(
          'My Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: showSortOptions,
            icon: Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort',
          ),
          IconButton(
            onPressed: () {
              themeProvider.toggleTheme();
            },
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: showCategoryFilter,
            icon: Icon(Icons.filter_list, color: Colors.white),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                    ? Color(0xFF2C2C2C)
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _searchController,
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search notes...",
                  hintStyle: TextStyle(
                    color: themeProvider.isDarkMode 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                  ),
                  icon: Icon(Icons.search, color: Colors.teal),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear, 
                            color: themeProvider.isDarkMode 
                                ? Colors.grey[400] 
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchKeyword = '';
                              refreshNotes();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value.trim();
                    _selectedCategory = null;
                    refreshNotes();
                  });
                },
              ),
            ),
          ),
          
          // Filter Chips
          if (_selectedCategory != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    avatar: Icon(Icons.filter_alt, size: 18, color: Colors.white),
                    label: Text(
                      _selectedCategory!,
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.teal,
                    deleteIcon: Icon(Icons.close, size: 18, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                        refreshNotes();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Notes List
          Expanded(
            child: FutureBuilder<List<NoteModel>>(
              future: notes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateWidget(
                    title: _searchKeyword.isNotEmpty
                        ? 'No Results'
                        : 'No Notes Yet',
                    message: _searchKeyword.isNotEmpty
                        ? 'Try searching with different keywords'
                        : 'Tap the + button to create your first note',
                    icon: _searchKeyword.isNotEmpty
                        ? Icons.search_off
                        : Icons.note_add_outlined,
                  );
                } else {
                  final items = sortNotes(snapshot.data!);
                  
                  return ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.all(16),
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final note = items[index];
                      
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / items.length) * 0.5,
                              ((index + 1) / items.length) * 0.5 + 0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index / items.length) * 0.5,
                                ((index + 1) / items.length) * 0.5 + 0.5,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: NoteCard(
                            note: note,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UpdateNoteScreen(note: note),
                                ),
                              );
                              refreshNotes();
                            },
                            onDelete: () => showDeleteDialog(context, note),
                            onTogglePin: () => togglePin(note),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateNoteScreen()),
          );
          refreshNotes();
        },
        backgroundColor: Colors.teal,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Note',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 6,
      ),
    );
  }
}
                