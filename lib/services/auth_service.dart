import 'package:firebase_auth/firebase_auth.dart';

/// Простая авторизация email/password.
/// Для 12 сотрудников аккаунты создаются вручную в Firebase Console
/// (Authentication -> Users -> Add user), self-signup не нужен.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Человекочитаемое сообщение об ошибке для UI.
  String mapErrorToMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-email':
          return 'Пользователь не найден';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Неверный пароль';
        case 'user-disabled':
          return 'Учётная запись отключена';
        case 'too-many-requests':
          return 'Слишком много попыток входа, попробуйте позже';
        default:
          return 'Ошибка входа: ${error.message}';
      }
    }
    return 'Неизвестная ошибка входа';
  }
}
