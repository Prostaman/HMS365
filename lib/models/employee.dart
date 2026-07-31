import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String uid;
  final String name;
  final String email;
  final bool isManager;

  Employee({
    required this.uid,
    required this.name,
    required this.email,
    this.isManager = false,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isManager: data['isManager'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isManager': isManager,
    };
  }
}
