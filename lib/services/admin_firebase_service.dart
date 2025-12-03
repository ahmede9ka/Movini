// lib/services/admin_firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminFirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get admin dashboard statistics - UPDATED for favorites structure
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get all users to calculate total users
      final usersQuery = await _firestore.collection('users').get();
      final totalUsers = usersQuery.docs.length;

      // Get total movies from favorites across all users
      int totalMovies = 0;
      int totalFavorites = 0;
      Set<String> uniqueMovieIds = {}; // To track unique movies

      final users = await _firestore.collection('users').get();
      for (final userDoc in users.docs) {
        try {
          final favs = await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .get();

          totalFavorites += favs.docs.length;

          // Extract unique movie IDs
          for (final favDoc in favs.docs) {
            uniqueMovieIds.add(favDoc.id);
          }
        } catch (e) {
          // User might not have favorites
          if (kDebugMode) {
            print('Error getting favorites for user ${userDoc.id}: $e');
          }
        }
      }

      totalMovies = uniqueMovieIds.length;

      // Get today's views if movie_views collection exists
      int todaysViews = 0;
      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final viewsQuery = await _firestore
            .collection('movie_views')
            .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
            .where('timestamp', isLessThan: endOfDay)
            .get();
        todaysViews = viewsQuery.docs.length;
      } catch (e) {
        todaysViews = 0;
      }

      // Get active users (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      int activeUsers = 0;
      try {
        final activeUsersQuery = await _firestore
            .collection('users')
            .where('lastActive', isGreaterThanOrEqualTo: weekAgo)
            .get();
        activeUsers = activeUsersQuery.docs.length;
      } catch (e) {
        activeUsers = totalUsers; // Default to all users if field doesn't exist
      }

      return {
        'totalMovies': totalMovies,
        'totalUsers': totalUsers,
        'todaysViews': todaysViews,
        'totalFavorites': totalFavorites,
        'activeUsers': activeUsers,
        'revenue': 0.0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting dashboard stats: $e');
      }
      return {
        'totalMovies': 0,
        'totalUsers': 0,
        'todaysViews': 0,
        'totalFavorites': 0,
        'activeUsers': 0,
        'revenue': 0.0,
      };
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'name': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
          'photoURL': data['photoURL'] ?? '',
          'role': data['role'] ?? 'user',
          'isActive': data['isActive'] ?? true,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'lastLogin': (data['lastLogin'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users: $e');
      }
      return [];
    }
  }

  // NEW: Get all movies from favorites across all users
  Future<List<Map<String, dynamic>>> getAllMovies() async {
    try {
      Set<String> uniqueMovieIds = {};
      Map<String, Map<String, dynamic>> moviesMap = {};
      Map<String, int> favoriteCounts = {};

      // Get all users
      final users = await _firestore.collection('users').get();

      for (final userDoc in users.docs) {
        try {
          final favs = await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .get();

          for (final favDoc in favs.docs) {
            final movieId = favDoc.id;
            final movieData = favDoc.data();

            uniqueMovieIds.add(movieId);

            // Increment favorite count
            favoriteCounts[movieId] = (favoriteCounts[movieId] ?? 0) + 1;

            // Store movie data if not already stored
            if (!moviesMap.containsKey(movieId)) {
              moviesMap[movieId] = {
                'id': movieId,
                'title': movieData['title'] ?? 'Unknown Title',
                'description': movieData['description'] ?? '',
                'year': movieData['year'] ?? '',
                'genre': movieData['genre'] is List ? movieData['genre'] : [],
                'rating': (movieData['rating'] ?? 0.0).toDouble(),
                'posterUrl': movieData['posterUrl'] ?? '',
                'views': movieData['views'] ?? 0,
                'favoriteCount': 1,
                'createdAt': (movieData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'updatedAt': (movieData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }
          }
        } catch (e) {
          // User might not have favorites
          continue;
        }
      }

      // Update favorite counts
      for (var movieId in moviesMap.keys) {
        moviesMap[movieId]!['favoriteCount'] = favoriteCounts[movieId] ?? 0;
      }

      // Convert to list and sort by favorite count (descending)
      List<Map<String, dynamic>> movies = moviesMap.values.toList();
      movies.sort((a, b) => (b['favoriteCount'] ?? 0).compareTo(a['favoriteCount'] ?? 0));

      return movies;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting movies from favorites: $e');
      }
      return [];
    }
  }

  // NEW: Get movie details by ID from any user's favorites
  Future<Map<String, dynamic>?> getMovieById(String movieId) async {
    try {
      // Find the movie in any user's favorites
      final users = await _firestore.collection('users').get();

      for (final userDoc in users.docs) {
        try {
          final movieDoc = await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .doc(movieId)
              .get();

          if (movieDoc.exists) {
            final movieData = movieDoc.data();

            // Count how many users have this movie as favorite
            int favoriteCount = 0;
            for (final otherUserDoc in users.docs) {
              try {
                final otherMovieDoc = await _firestore
                    .collection('favorites')
                    .doc(otherUserDoc.id)
                    .collection('Movies')
                    .doc(movieId)
                    .get();

                if (otherMovieDoc.exists) {
                  favoriteCount++;
                }
              } catch (e) {
                continue;
              }
            }

            return {
              'id': movieId,
              'title': movieData?['title'] ?? 'Unknown Title',
              'description': movieData?['description'] ?? '',
              'year': movieData?['year'] ?? '',
              'genre': movieData?['genre'] is List ,
              'rating': (movieData?['rating'] ?? 0.0).toDouble(),
              'posterUrl': movieData?['posterUrl'] ?? '',
              'views': movieData?['views'] ?? 0,
              'favoriteCount': favoriteCount,
              'createdAt': (movieData?['createdAt'] as Timestamp?)?.toDate(),
              'updatedAt': (movieData?['updatedAt'] as Timestamp?)?.toDate(),
            };
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting movie by ID: $e');
      }
      return null;
    }
  }

  // NEW: Delete movie from all users' favorites
  Future<void> deleteMovie(String movieId) async {
    try {
      // Get all users
      final users = await _firestore.collection('users').get();

      // Delete movie from each user's favorites
      for (final userDoc in users.docs) {
        try {
          await _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .doc(movieId)
              .delete();
        } catch (e) {
          // Movie might not exist in this user's favorites
          continue;
        }
      }

      // Log activity (if activities collection exists)
      try {
        await addActivity(
          type: 'movie_deleted',
          title: 'Movie deleted',
          description: 'Movie removed from all favorites',
        );
      } catch (e) {
        // Activities collection might not exist
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting movie: $e');
      }
      rethrow;
    }
  }

  // NEW: Get top movies by favorite count
  Future<List<Map<String, dynamic>>> getTopMovies({int limit = 10}) async {
    try {
      final movies = await getAllMovies();
      return movies.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting top movies: $e');
      }
      return [];
    }
  }

  // NEW: Search movies in favorites
  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    try {
      final movies = await getAllMovies();
      return movies.where((movie) {
        final title = (movie['title'] ?? '').toLowerCase();
        final description = (movie['description'] ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching movies: $e');
      }
      return [];
    }
  }

  // NEW: Get users who favorited a specific movie
  Future<List<Map<String, dynamic>>> getUsersWhoFavoritedMovie(String movieId) async {
    try {
      final users = await getAllUsers();
      final List<Map<String, dynamic>> usersWithMovie = [];

      for (final user in users) {
        try {
          final movieDoc = await _firestore
              .collection('favorites')
              .doc(user['id'])
              .collection('Movies')
              .doc(movieId)
              .get();

          if (movieDoc.exists) {
            usersWithMovie.add(user);
          }
        } catch (e) {
          continue;
        }
      }

      return usersWithMovie;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users who favorited movie: $e');
      }
      return [];
    }
  }

  // NEW: Add a movie to system (add to a default admin user's favorites)
  Future<void> addMovie(Map<String, dynamic> movieData) async {
    try {
      // First, find or create a default admin user for storing movies
      final adminUsers = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      String adminUserId;
      if (adminUsers.docs.isEmpty) {
        // Create a default admin user if none exists
        final newUser = await _firestore.collection('users').add({
          'email': 'system@moviemanager.com',
          'role': 'admin',
          'prenom': 'System',
          'nom': 'Admin',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        adminUserId = newUser.id;
      } else {
        adminUserId = adminUsers.docs.first.id;
      }

      // Generate a unique movie ID
      final movieId = 'movie_${DateTime.now().millisecondsSinceEpoch}';

      // Add movie to admin user's favorites
      await _firestore
          .collection('favorites')
          .doc(adminUserId)
          .collection('Movies')
          .doc(movieId)
          .set({
        ...movieData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'views': 0,
        'rating': 0.0,
      });

      // Log activity (if activities collection exists)
      try {
        await addActivity(
          type: 'movie_added',
          title: 'Movie added',
          description: 'New movie: ${movieData['title']}',
        );
      } catch (e) {
        // Activities collection might not exist
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding movie: $e');
      }
      rethrow;
    }
  }

  // NEW: Update movie in all users' favorites
  Future<void> updateMovie(String movieId, Map<String, dynamic> updates) async {
    try {
      // Get all users who have this movie in favorites
      final users = await _firestore.collection('users').get();

      for (final userDoc in users.docs) {
        try {
          final movieRef = _firestore
              .collection('favorites')
              .doc(userDoc.id)
              .collection('Movies')
              .doc(movieId);

          final movieDoc = await movieRef.get();

          if (movieDoc.exists) {
            await movieRef.update({
              ...updates,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          continue;
        }
      }

      // Log activity (if activities collection exists)
      try {
        await addActivity(
          type: 'movie_updated',
          title: 'Movie updated',
          description: 'Movie updated: ${updates['title']}',
        );
      } catch (e) {
        // Activities collection might not exist
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating movie: $e');
      }
      rethrow;
    }
  }

  // NEW: Add activity log (if activities collection exists)
  Future<void> addActivity({
    required String type,
    required String title,
    required String description,
    String? userId,
    String? userName,
  }) async {
    try {
      await _firestore.collection('activities').add({
        'type': type,
        'title': title,
        'description': description,
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding activity: $e');
      }
      // Don't rethrow - activities are optional
    }
  }

  // Rest of existing methods remain the same...
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        dynamic timestamp = data['timestamp'];
        if (timestamp is Timestamp) {
          timestamp = timestamp.toDate();
        }
        return {
          'id': doc.id,
          'type': data['type'] ?? '',
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'timestamp': timestamp,
          'userId': data['userId'],
          'userName': data['userName'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent activities: $e');
      }
      return [];
    }
  }

  // Get admin profile
  Future<Map<String, dynamic>?> getAdminProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData != null) {
        dynamic lastLogin = userData['lastLogin'];
        dynamic createdAt = userData['createdAt'];

        if (lastLogin is Timestamp) lastLogin = lastLogin.toDate();
        if (createdAt is Timestamp) createdAt = createdAt.toDate();

        return {
          'id': userDoc.id,
          'name': '${userData['prenom'] ?? ''} ${userData['nom'] ?? ''}'.trim(),
          'email': userData['email'] ?? '',
          'role': userData['role'] ?? 'user',
          'photoURL': userData['photoURL'] ?? '',
          'lastLogin': lastLogin,
          'createdAt': createdAt,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting admin profile: $e');
      }
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return userData?['role'] == 'admin' || userData?['role'] == 'Admin';
    } catch (e) {
      if (kDebugMode) {
        print('Error checking admin status: $e');
      }
      return false;
    }
  }

  // Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await addActivity(
        type: 'user_updated',
        title: 'User ${isActive ? 'activated' : 'deactivated'}',
        description: 'User status updated',
        userId: userId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
      rethrow;
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await addActivity(
        type: 'user_updated',
        title: 'User role updated',
        description: 'Role changed to $role',
        userId: userId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      // Delete user's favorites
      try {
        await _firestore.collection('favorites').doc(userId).delete();
      } catch (e) {
        // Ignore if favorites don't exist
      }

      // Log activity
      await addActivity(
        type: 'user_deleted',
        title: 'User deleted',
        description: 'User account removed',
        userId: userId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
      rethrow;
    }
  }

  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final users = await getAllUsers();
      return users.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching users: $e');
      }
      return [];
    }
  }
}