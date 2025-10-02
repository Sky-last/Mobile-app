import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:notes_app_5sia1/database/database_helper.dart';
import 'package:notes_app_5sia1/models/note_model.dart';
import 'package:notes_app_5sia1/services/notification_service.dart';

class UpdateNoteScreen extends StatefulWidget {
  final NoteModel note;

  const UpdateNoteScreen({super.key, required this.note});

  @override
  State<UpdateNoteScreen> createState() => _UpdateNoteScreenState();
}

class _UpdateNoteScreenState extends State<UpdateNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  final categoryController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final db = DatabaseHelper();
  final notificationService = NotificationService();

  // NEW: Variables untuk fitur baru
  String? selectedCategory;
  Color selectedColor = Colors.teal;
  DateTime? reminderDateTime;
  bool hasReminder = false;
  int isPinned = 0;

  List<String> existingCategories = [];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.noteTitle);
    contentController = TextEditingController(text: widget.note.noteContent);
    
    // Load existing note data
    selectedCategory = widget.note.category;
    isPinned = widget.note.isPinned;
    
    // Parse color
    if (widget.note.categoryColor != null) {
      try {
        selectedColor = Color(
          int.parse(widget.note.categoryColor!.replaceFirst('#', '0xFF'))
        );
      } catch (e) {
        selectedColor = Colors.teal;
      }
    }
    
    // Parse reminder
    if (widget.note.reminderTime != null) {
      reminderDateTime = DateTime.parse(widget.note.reminderTime!);
      hasReminder = true;
    }
    
    loadCategories();
  }

  Future<void> loadCategories() async {
    final categories = await db.getAllCategories();
    setState(() {
      existingCategories = categories;
    });
  }

  Future<void> updateNote() async {
    try {
      // Convert color to hex string
      String? colorHex;
      if (selectedCategory != null) {
        colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';
      }

      // Create updated note model
      final updatedNote = NoteModel(
        noteId: widget.note.noteId,
        noteTitle: titleController.text,
        noteContent: contentController.text,
        createdAt: widget.note.createdAt,
        category: selectedCategory,
        categoryColor: colorHex,
        isPinned: isPinned,
        reminderTime: reminderDateTime?.toIso8601String(),
      );

      int result = await db.updateNote(updatedNote);

      if (!mounted) return;

      if (result > 0) {
        // Cancel existing notification
        await notificationService.cancelNotification(widget.note.noteId!);
        
        // Schedule new notification jika ada reminder
        if (hasReminder && reminderDateTime != null) {
          // Only schedule if reminder is in future
          if (reminderDateTime!.isAfter(DateTime.now())) {
            await notificationService.scheduleNotification(
              id: widget.note.noteId!,
              title: 'Reminder: ${titleController.text}',
              body: contentController.text.length > 50
                  ? '${contentController.text.substring(0, 50)}...'
                  : contentController.text,
              scheduledTime: reminderDateTime!,
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note Updated Successfully'),
            backgroundColor: Colors.teal[400],
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update note. Please try again'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show color picker dialog
  void showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick Category Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              setState(() {
                selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  // Show category selector dialog
  void showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select or Create Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Create new category
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'New Category',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (categoryController.text.isNotEmpty) {
                        setState(() {
                          selectedCategory = categoryController.text;
                          if (!existingCategories.contains(selectedCategory)) {
                            existingCategories.add(selectedCategory!);
                          }
                        });
                        categoryController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
              Divider(),
              // Existing categories
              ...existingCategories.map((category) => ListTile(
                title: Text(category),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedCategory = null;
              });
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show date time picker for reminder
  Future<void> selectReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: reminderDateTime ?? DateTime.now().add(Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: reminderDateTime != null 
            ? TimeOfDay.fromDateTime(reminderDateTime!)
            : TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          reminderDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          hasReminder = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Note', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                updateNote();
              }
            },
            icon: Icon(Icons.check),
            color: Colors.white,
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Title is Required";
                    }
                    return null;
                  },
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "title",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                
                // Content field
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Content is Required";
                    }
                    return null;
                  },
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "content",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 20),

                // Category section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategory ?? 'No category selected',
                                style: TextStyle(
                                  color: selectedCategory != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            if (selectedCategory != null)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.category),
                              onPressed: showCategoryDialog,
                            ),
                            if (selectedCategory != null)
                              IconButton(
                                icon: Icon(Icons.color_lens),
                                onPressed: showColorPickerDialog,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Reminder section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reminder',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Switch(
                              value: hasReminder,
                              onChanged: (value) {
                                if (value) {
                                  selectReminderDateTime();
                                } else {
                                  setState(() {
                                    hasReminder = false;
                                    reminderDateTime = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        if (hasReminder && reminderDateTime != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${reminderDateTime!.day}/${reminderDateTime!.month}/${reminderDateTime!.year} at ${reminderDateTime!.hour}:${reminderDateTime!.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                onPressed: selectReminderDateTime,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}