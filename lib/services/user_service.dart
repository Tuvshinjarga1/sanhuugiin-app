import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Хэрэглэгчийн мэдээлэл авах
  Future<UserModel> getUserById(String uid) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(uid).get();

      if (!docSnapshot.exists) {
        throw Exception('Хэрэглэгч олдсонгүй');
      }

      return UserModel.fromMap(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      rethrow;
    }
  }

  // Шинэ хэрэглэгч үүсгэх
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн мэдээлэл шинэчлэх
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн үлдэгдэл шинэчлэх
  Future<void> updateBalance(String uid, double amount) async {
    try {
      // Хэрэглэгчийн одоогийн мэдээлэл авах
      final userDoc = await _firestore.collection(_collection).doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('Хэрэглэгч олдсонгүй');
      }

      // Одоогийн үлдэгдэлийг авах
      final userData = userDoc.data()!;
      final currentBalance = userData['balance'] != null
          ? (userData['balance'] as num).toDouble()
          : 0.0;

      // Шинэ үлдэгдэл тооцох
      final newBalance = currentBalance + amount;

      // Үлдэгдэлийг шинэчлэх
      await _firestore.collection(_collection).doc(uid).update({
        'balance': newBalance,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн сүүлийн нэвтрэлтийн хугацааг шинэчлэх
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн нэрээр хайх
  Future<List<UserModel>> searchUsersByName(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('displayName', isGreaterThanOrEqualTo: name)
          .where('displayName', isLessThanOrEqualTo: name + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
