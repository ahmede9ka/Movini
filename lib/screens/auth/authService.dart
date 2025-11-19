import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up with email, password and user data
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required File? image,
  }) async {
    try {
      // 1. Create user with Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // 2. Upload photo to Firebase Storage
      String? photoURL;
      if (image != null) {
        photoURL = await _uploadImage(userId, image);
      }

      // 3. Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'nom': lastName.trim(),
        'prenom': firstName.trim(),
        'age': age,
        'email': email.trim(),
        'photoURL': photoURL ?? '',
        'role': 'user',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Update display name and photo in Firebase Auth
      await userCredential.user!
          .updateDisplayName('$firstName $lastName');
      if (photoURL != null) {
        await userCredential.user!.updatePhotoURL(photoURL);
      }

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Sign In with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Check if user is active
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await signOut();
        return {
          'success': false,
          'message': 'User account not found',
        };
      }

      final userData = userDoc.data()!;
      if (userData['isActive'] == false) {
        await signOut();
        return {
          'success': false,
          'message': 'Your account has been deactivated. Please contact support.',
        };
      }

      return {
        'success': true,
        'message': 'Login successful',
        'user': userCredential.user,
        'role': userData['role'],
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final role = await getUserRole(currentUser!.uid);
    return role == 'admin';
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(String userId, File image) async {
    try {
      final ref = _storage.ref().child('user_photos').child('$userId.jpg');
      await ref.putFile(image);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Get error message from Firebase Auth error code
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      default:
        return 'An error occurred. Please try again';
    }
  }

  // Delete user account (optional)
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      final userId = currentUser!.uid;

      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete favorites
      final favoritesQuery = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .get();
      for (var doc in favoritesQuery.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('favorites').doc(userId).delete();

      // Delete profile photo
      try {
        await _storage.ref().child('user_photos').child('$userId.jpg').delete();
      } catch (e) {
        print('Error deleting photo: $e');
      }

      // Delete auth user
      await currentUser!.delete();

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting account: $e',
      };
    }
  }
}