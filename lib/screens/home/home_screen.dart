import 'package:flutter/material.dart';
import '../../models/todo.dart';
import '../../services/todo_service.dart';
import '../../widgets/todo_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'add_todo_screen.dart';
import 'edit_todo_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TodoFilter { all, completed, incomplete }
enum TodoSort { az, za }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodoService _todoService = TodoService();
  final AuthService _authService = AuthService();
  TodoFilter _filter = TodoFilter.all;
  TodoSort _sort = TodoSort.az;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Todo? _recentlyDeleted;

  void _addTodo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTodoScreen()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To-do added successfully!')),
      );
      setState(() {}); // Refresh the list if needed
    }
  }

  void _editTodo(Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditTodoScreen(todo: todo)),
    );
  }

  void _deleteTodo(String id) async {
    final todos = await _todoService.getTodos().first;
    final todo = todos.firstWhere((t) => t.id == id, orElse: () => Todo(id: '', title: ''));
    if (todo.id == '') return;
    setState(() {
      _recentlyDeleted = todo;
    });
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete To-Do'),
        content: const Text('Are you sure you want to delete this to-do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _todoService.deleteTodo(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('To-do deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                if (_recentlyDeleted != null) {
                  await _todoService.addTodo(_recentlyDeleted!);
                  setState(() {
                    _recentlyDeleted = null;
                  });
                }
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _signOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You're logging out...")),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _markAll(bool completed) async {
    final todos = await _todoService.getTodos().first;
    for (final todo in todos) {
      if (todo.isDone != completed) {
        await _todoService.updateTodo(
          Todo(
            id: todo.id,
            title: todo.title,
            description: todo.description,
            isDone: completed,
          ),
        );
      }
    }
  }

  void _deleteAllCompleted() async {
    final todos = await _todoService.getTodos().first;
    for (final todo in todos) {
      if (todo.isDone) {
        await _todoService.deleteTodo(todo.id);
      }
    }
  }

  void _togglePin(Todo todo) async {
    final updated = Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isDone: todo.isDone,
      pinned: !todo.pinned,
    );
    await _todoService.updateTodo(updated);
  }

  List<Todo> _applyFilterAndSort(List<Todo> todos) {
    List<Todo> filtered = todos;
    if (_filter == TodoFilter.completed) {
      filtered = todos.where((t) => t.isDone).toList();
    } else if (_filter == TodoFilter.incomplete) {
      filtered = todos.where((t) => !t.isDone).toList();
    }
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.title.toLowerCase().contains(_searchText.toLowerCase()) ||
        (t.description ?? '').toLowerCase().contains(_searchText.toLowerCase())
      ).toList();
    }
    filtered.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1; // pinned first
      }
      return _sort == TodoSort.az
        ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
        : b.title.toLowerCase().compareTo(a.title.toLowerCase());
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          if (user != null && user.displayName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  'Hi, ${user.displayName!}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ),
          if (user != null && user.photoURL != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') _signOut();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                child: CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                  radius: 18,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                child: Icon(Icons.person),
                radius: 18,
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_completed') _markAll(true);
              if (value == 'mark_all_incomplete') _markAll(false);
              if (value == 'delete_completed') _deleteAllCompleted();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_completed',
                child: Text('Mark all as completed'),
              ),
              const PopupMenuItem(
                value: 'mark_all_incomplete',
                child: Text('Mark all as incomplete'),
              ),
              const PopupMenuItem(
                value: 'delete_completed',
                child: Text('Delete all completed'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search to-dos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == TodoFilter.all,
                  onSelected: (_) => setState(() => _filter = TodoFilter.all),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: _filter == TodoFilter.completed,
                  onSelected: (_) => setState(() => _filter = TodoFilter.completed),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Incomplete'),
                  selected: _filter == TodoFilter.incomplete,
                  onSelected: (_) => setState(() => _filter = TodoFilter.incomplete),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_sort == TodoSort.az ? Icons.sort_by_alpha : Icons.sort),
                  tooltip: _sort == TodoSort.az ? 'Sort Z-A' : 'Sort A-Z',
                  onPressed: () => setState(() {
                    _sort = _sort == TodoSort.az ? TodoSort.za : TodoSort.az;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Todo>>(
              stream: _todoService.getTodos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('Error: \\${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final todos = _applyFilterAndSort(snapshot.data ?? []);
                if (todos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, color: Colors.grey[400], size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No to-dos yet!\nTap + to add your first one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return TodoTile(
                      todo: todo,
                      onEdit: () => _editTodo(todo),
                      onDelete: () => _deleteTodo(todo.id),
                      onTogglePin: () => _togglePin(todo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
