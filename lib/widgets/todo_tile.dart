import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTogglePin;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onEdit,
    required this.onDelete,
    this.onTogglePin,
  });

  void _toggleDone(bool? value) {
    if (value == null) return;
    final updatedTodo = Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isDone: value,
      pinned: todo.pinned,
    );
    TodoService().updateTodo(updatedTodo);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.isDone,
        onChanged: _toggleDone,
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: todo.description != null && todo.description!.isNotEmpty
          ? Text(todo.description!)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              todo.pinned ? Icons.star : Icons.star_border,
              color: todo.pinned ? Colors.amber : null,
            ),
            tooltip: todo.pinned ? 'Unpin' : 'Pin',
            onPressed: onTogglePin,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
} 