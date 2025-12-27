import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todosKey = 'todos';
  List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);
  List<Todo> get activeTodos => _todos.where((t) => !t.isCompleted).toList();
  List<Todo> get completedTodos => _todos.where((t) => t.isCompleted).toList();
  List<Todo> get todaysTodos => _todos.where((t) => t.isDueToday).toList();
  List<Todo> get importantTodos => _todos.where((t) => t.isImportant).toList();

  /// Load todos from local storage
  Future<void> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getString(_todosKey);

    if (todosJson != null) {
      final List<dynamic> todosList = jsonDecode(todosJson);
      _todos = todosList.map((json) => Todo.fromJson(json)).toList();
    }
  }

  /// Save todos to local storage
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = jsonEncode(_todos.map((t) => t.toJson()).toList());
    await prefs.setString(_todosKey, todosJson);
  }

  /// Add a new todo
  Future<Todo> addTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 2,
  }) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
    );

    _todos.add(todo);
    await _saveTodos();
    return todo;
  }

  /// Update an existing todo
  Future<void> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      await _saveTodos();
    }
  }

  /// Toggle todo completion
  Future<void> toggleComplete(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
      await _saveTodos();
    }
  }

  /// Delete a todo
  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((t) => t.id == id);
    await _saveTodos();
  }

  /// Get summary for voice call
  String getTodoSummary() {
    final active = activeTodos;
    final today = todaysTodos;
    final important = importantTodos.where((t) => !t.isCompleted).toList();

    if (active.isEmpty) {
      return "You have no pending tasks. Would you like to add some?";
    }

    final buffer = StringBuffer();
    buffer.write("You have ${active.length} pending task");
    if (active.length > 1) buffer.write("s");
    buffer.write(". ");

    if (today.isNotEmpty) {
      buffer.write("${today.length} due today. ");
    }

    if (important.isNotEmpty) {
      buffer.write("Important: ");
      buffer.write(important.take(3).map((t) => t.title).join(", "));
      buffer.write(". ");
    }

    return buffer.toString();
  }

  /// Get greeting based on time of day
  String getTimeBasedGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }

    return "$greeting, $name!";
  }
}
