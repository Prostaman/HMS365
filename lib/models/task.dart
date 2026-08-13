import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.description,
    this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
    };
  }
}
