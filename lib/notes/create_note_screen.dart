import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:notes_app_5sia1/database/database_helper.dart';
import 'package:notes_app_5sia1/models/note_model.dart';
import 'package:notes_app_5sia1/services/notification_service.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final categoryController = TextEditingController();

  final formkey = GlobalKey<FormState>();
  final db = DatabaseHelper();
  final notificationService = NotificationService();

  // NEW: Variables untuk fitur baru
  String? selectedCategory;
  Color selectedColor = Colors.teal;
  DateTime? reminderDateTime;
  bool hasReminder = false;

  List<String> existingCategories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final categories = await db.getAllCategories();
    setState(() {
      existingCategories = categories;
    });
  }

  Future<void> createNote() async {
    try {
      // Convert color to hex string
      String colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';

      // Create note model
      final note = NoteModel(
        noteTitle: titleController.text,
        noteContent: contentController.text,
        createdAt: DateTime.now().toIso8601String(),
        category: selectedCategory,
        categoryColor: selectedCategory != null ? colorHex : null,
        isPinned: 0,
        reminderTime: reminderDateTime?.toIso8601String(),
      );

      int result = await db.createNote(note);

      if (!mounted) return;

      if (result > 0) {
        // Schedule notification jika ada reminder
        if (hasReminder && reminderDateTime != null) {
          await notificationService.scheduleNotification(
            id: result, // Menggunakan noteId sebagai notification ID
            title: 'Reminder: ${titleController.text}',
            body: contentController.text.length > 50
                ? '${contentController.text.substring(0, 50)}...'
                : contentController.text,
            scheduledTime: reminderDateTime!,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note created successfully!'),
            backgroundColor: Colors.teal[400],
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create note. Please try again.'),
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
        backgroundColor: Colors.teal,
        title: Text("Created note", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              if (formkey.currentState!.validate()) {
                createNote();
              }
            },
            icon: Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
      body: Form(
        key: formkey,
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
                              Text(
                                '${reminderDateTime!.day}/${reminderDateTime!.month}/${reminderDateTime!.year} at ${reminderDateTime!.hour}:${reminderDateTime!.minute.toString().padLeft(2, '0')}',
                              ),
                              Spacer(),
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