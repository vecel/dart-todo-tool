library todo_annotations;

enum Priority {
  low,
  medium,
  high,
  critical
}

class Todo {
  final String desccription;
  final Priority? priority;

  const Todo(this.desccription, {
    this.priority
  });
}