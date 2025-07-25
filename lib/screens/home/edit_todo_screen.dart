import 'package:flutter/material.dart';
import '../../models/todo.dart';
import '../../services/todo_service.dart';

class EditTodoScreen extends StatefulWidget {
  final Todo todo;
  const EditTodoScreen({super.key, required this.todo});

  @override
  State<EditTodoScreen> createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isLoading = false;
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descController = TextEditingController(text: widget.todo.description ?? '');
    _isDone = widget.todo.isDone;
  }

  void _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final updatedTodo = Todo(
      id: widget.todo.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      isDone: _isDone,
    );
    await TodoService().updateTodo(updatedTodo);
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit To-Do')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              CheckboxListTile(
                value: _isDone,
                onChanged: (val) => setState(() => _isDone = val ?? false),
                title: const Text('Completed'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveTodo,
                      child: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
