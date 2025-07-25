import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo.dart';

class TodoService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Stream<List<Todo>> getTodos() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      // Return an empty stream if not authenticated
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Todo.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addTodo(Todo todo) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .add(todo.toMap());
  }

  Future<void> updateTodo(Todo todo) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todo.id)
        .update(todo.toMap());
  }

  Future<void> deleteTodo(String todoId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId)
        .delete();
  }
}
