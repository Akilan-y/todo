import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../models/todo.dart';
import '../../services/todo_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_app/screens/home/home_screen.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  DateTime? _reminderTime;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(const InitializationSettings(android: android, iOS: ios));
    if (Platform.isIOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _pickReminderTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _reminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _scheduleNotification(Todo todo) async {
    if (todo.reminderTime == null) return;
    // Check notification permission
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
      if (!status.isGranted) {
        // Show a message or handle gracefully
        print('Notification permission not granted. Skipping notification.');
        return;
      }
    }
    await _notifications.zonedSchedule(
      todo.hashCode,
      'To-Do Reminder',
      todo.title,
      tz.TZDateTime.from(todo.reminderTime!, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('todo_reminder', 'To-Do Reminders'),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> checkAndPromptNotificationPermission(BuildContext context) async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Notifications are disabled. Please enable them in your device settings to receive reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  void _saveTodo() async {
    print('SaveTodo called');
    if (!_formKey.currentState!.validate()) {
      print('Form not valid');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.isEmpty) {
      print('User not signed in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be signed in to add a task.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      print('Creating todo object');
      final todo = Todo(
        id: '', // Firestore will generate the ID
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isDone: false,
        pinned: false,
        reminderTime: _reminderTime,
      );
      print('Adding todo to Firestore');
      await TodoService().addTodo(todo);
      print('Todo added. Scheduling notification...');
      // Prompt user to enable notifications if denied
      await checkAndPromptNotificationPermission(context);
      try {
        await _scheduleNotification(todo);
        print('Notification scheduled');
      } catch (notifError) {
        print('Notification scheduling failed: ${notifError.toString()}');
      }
      print('Waiting 0.5s');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        print('About to navigate');
        setState(() => _isLoading = false);
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/home', (route) => false);
        print('Navigation called');
      } else {
        print('Widget not mounted');
      }
    } catch (e) {
      print('Error in _saveTodo: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: $e')),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22232A),
        elevation: 0,
        title: const Text('Add To-Do', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Title',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF22232A),
                    hintText: 'Enter a title',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF22232A),
                    hintText: 'Enter a description',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reminderTime == null
                            ? 'No reminder set'
                            : 'Reminder: ${_reminderTime.toString()}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF35363F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _pickReminderTime,
                      child: const Text('Set Reminder'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveTodo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F5B62),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Add'),
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
