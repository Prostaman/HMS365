import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  Employee({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Employee(
      uid: doc.id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'first_name': firstName, 'last_name': lastName, 'email': email};
  }
}
