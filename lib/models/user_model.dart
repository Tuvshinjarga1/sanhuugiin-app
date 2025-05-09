import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phone;
  final String? address;
  final double? balance;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phone,
    this.address,
    this.balance,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'balance': balance,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phone: map['phone'],
      address: map['address'],
      balance: map['balance']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phone,
    String? address,
    double? balance,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
