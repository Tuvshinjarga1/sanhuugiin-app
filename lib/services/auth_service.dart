import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Хэрэглэгчийн өөрчлөлт сонсох
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Одоогийн хэрэглэгчийг авах
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Бүртгүүлэх
  Future<UserCredential> signUp(
      String email, String password, String displayName) async {
    try {
      // Firebase Authentication-д бүртгүүлэх
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Хэрэглэгчийн нэрийг шинэчлэх
      await userCredential.user!.updateDisplayName(displayName);

      // Firestore-д хэрэглэгчийг хадгалах
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        balance: 0.0,
        createdAt: DateTime.now(),
      );

      await _userService.createUser(newUser);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Нэвтрэх
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Сүүлийн нэвтрэлтийн хугацааг шинэчлэх
      await _userService.updateLastLogin(userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Гарах
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Нууц үг сэргээх имэйл илгээх
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Нууц үг солих
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Хэрэглэгч нэвтрээгүй байна');
      }

      // Имэйл авах
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('Имэйл хаяг олдсонгүй');
      }

      // Одоогийн нууц үгийг шалгах
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Хэрэглэгчийг баталгаажуулах
      await user.reauthenticateWithCredential(credential);

      // Шинэ нууц үг
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн мэдээллийг авах
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Хэрэглэгчийн мэдээллийг шинэчлэх
  Future<void> updateUserProfile(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Хэрэглэгч нэвтрээгүй байна');
      }

      await user.updateDisplayName(displayName);
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн документ үүсгэх
  Future<void> _createUserDocument(
      String uid, String email, String displayName) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'balance': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
