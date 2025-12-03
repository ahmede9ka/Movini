import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a movie to favorites
  Future<Map<String, dynamic>> addToFavorites({
    required String movieId,
    required String movieTitle,
    required String year,
    required String posterUrl,
    required String rating,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final timestamp = DateTime.now();

      await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .doc(movieId)
          .set({
        'movieId': movieId,
        'movieTitle': movieTitle,
        'year': year,
        'posterUrl': posterUrl,
        'rating': rating,
        'addedAt': timestamp,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Added to favorites',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding to favorites: $e',
      };
    }
  }

  // Remove a movie from favorites
  Future<Map<String, dynamic>> removeFromFavorites(String movieId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .doc(movieId)
          .delete();

      return {
        'success': true,
        'message': 'Removed from favorites',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error removing from favorites: $e',
      };
    }
  }

  // Check if a movie is in favorites
  Future<bool> isFavorite(String movieId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .doc(movieId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get all favorites for current user
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Get favorites count
  Future<int> getFavoritesCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // Get user's favorites (non-stream version)
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting user favorites: $e');
      return [];
    }
  }

  // Clear all favorites
  Future<Map<String, dynamic>> clearAllFavorites() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final snapshot = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('movies')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return {
        'success': true,
        'message': 'All favorites cleared',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error clearing favorites: $e',
      };
    }
  }
}