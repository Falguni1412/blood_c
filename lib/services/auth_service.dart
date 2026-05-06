import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream to listen to auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper to create fake email
  String _emailFromPhone(String phone) => '$phone@bloodcare.com';

  // Sign In with Phone & Password
  Future<UserCredential> loginWithPhone(String phone, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: _emailFromPhone(phone),
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Upload Profile Photo
  Future<String?> uploadProfilePhoto(String uid, File photo) async {
    try {
      final ref = _storage.ref().child('user_profiles').child('$uid.jpg');
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (e) {
      // print('Error uploading photo: $e');
      return null;
    }
  }

  // Advanced Registration
  Future<UserCredential> registerWithPhone({
    required String phone,
    required String password,
    required String fullName,
    File? photo,
    required String role,
    required Map<String, dynamic> additionalDetails,
  }) async {
    final email = _emailFromPhone(phone);

    try {
      // 1. Try to create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await _saveUserData(
        result.user!,
        phone,
        fullName,
        photo,
        role,
        additionalDetails,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        // 2. If user exists, try to Log In
        try {
          UserCredential result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // CRITICAL: Save/Update the data so the Role is recorded!
          await _saveUserData(
            result.user!,
            phone,
            fullName,
            photo,
            role,
            additionalDetails,
          );

          return result;
        } catch (loginError) {
          // If login also fails (e.g. wrong password), throw the original "exists" error
          // or a specific "User exists, wrong password" error.
          throw FirebaseAuthException(
            code: 'user-exists-wrong-password',
            message: 'User already exists, but password didn\'t match.',
          );
        }
      }
      rethrow;
    }
  }

  Future<UserCredential> _saveUserData(
    User user,
    String phone,
    String fullName,
    File? photo,
    String role,
    Map<String, dynamic> details,
  ) async {
    String? photoUrl;
    if (photo != null) {
      photoUrl = await uploadProfilePhoto(user.uid, photo);
    }

    // Store in Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'mobileNumber': phone,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role,
      'details': details, // e.g. blood group, hospital, etc.
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update Auth Profile
    await user.updateDisplayName(fullName);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    return UserCredentialImpl(
      user,
    ); // Helper to return credential-like object or just fetch it
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'] as String?;
      }
      return null;
    } catch (e) {
      // print('Error returning role: $e');
      return null;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String phone) async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailFromPhone(phone));
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    File? photo,
    Map<String, dynamic>? details,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      User? user = _auth.currentUser;

      if (fullName != null) {
        updates['fullName'] = fullName;
        await user?.updateDisplayName(fullName);
      }

      if (photo != null) {
        String? photoUrl = await uploadProfilePhoto(uid, photo);
        if (photoUrl != null) {
          updates['photoUrl'] = photoUrl;
          await user?.updatePhotoURL(photoUrl);
        }
      }

      if (details != null) {
        updates['details'] = details;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Quick helper since we can't instantiate UserCredential easily
class UserCredentialImpl implements UserCredential {
  final User? _user;
  UserCredentialImpl(this._user);
  @override
  User? get user => _user;
  @override
  AuthCredential? get credential => null;
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}
