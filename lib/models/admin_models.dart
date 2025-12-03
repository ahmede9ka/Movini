// lib/models/admin_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStats {
  final int totalMovies;
  final int totalUsers;
  final int todaysViews;
  final int totalFavorites;
  final int activeUsers;
  final double revenue;

  AdminStats({
    required this.totalMovies,
    required this.totalUsers,
    required this.todaysViews,
    required this.totalFavorites,
    required this.activeUsers,
    required this.revenue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalMovies: json['totalMovies'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      todaysViews: json['todaysViews'] ?? 0,
      totalFavorites: json['totalFavorites'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class AdminActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  AdminActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  factory AdminActivity.fromJson(Map<String, dynamic> json) {
    // Handle timestamp conversion
    DateTime timestamp;

    final timestampValue = json['timestamp'];

    if (timestampValue == null) {
      timestamp = DateTime.now();
    } else if (timestampValue is Timestamp) {
      timestamp = timestampValue.toDate();
    } else if (timestampValue is DateTime) {
      timestamp = timestampValue;
    } else if (timestampValue is String) {
      try {
        timestamp = DateTime.parse(timestampValue);
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }

    return AdminActivity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: timestamp,
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
    );
  }
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    // Handle timestamp conversion
    DateTime createdAt;

    final createdAtValue = json['createdAt'];

    if (createdAtValue == null) {
      createdAt = DateTime.now();
    } else if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
    } else if (createdAtValue is String) {
      try {
        createdAt = DateTime.parse(createdAtValue);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return AdminNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['isRead'] == true,
      createdAt: createdAt,
    );
  }
}

class AdminProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? photoURL;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoURL,
    this.lastLogin,
    this.createdAt,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    // Handle timestamp conversions
    DateTime? lastLogin;
    final lastLoginValue = json['lastLogin'];

    if (lastLoginValue != null) {
      if (lastLoginValue is Timestamp) {
        lastLogin = lastLoginValue.toDate();
      } else if (lastLoginValue is DateTime) {
        lastLogin = lastLoginValue;
      } else if (lastLoginValue is String) {
        try {
          lastLogin = DateTime.parse(lastLoginValue);
        } catch (e) {
          lastLogin = null;
        }
      }
    }

    DateTime? createdAt;
    final createdAtValue = json['createdAt'];

    if (createdAtValue != null) {
      if (createdAtValue is Timestamp) {
        createdAt = createdAtValue.toDate();
      } else if (createdAtValue is DateTime) {
        createdAt = createdAtValue;
      } else if (createdAtValue is String) {
        try {
          createdAt = DateTime.parse(createdAtValue);
        } catch (e) {
          createdAt = null;
        }
      }
    }

    return AdminProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'admin',
      photoURL: json['photoURL']?.toString(),
      lastLogin: lastLogin,
      createdAt: createdAt,
    );
  }
}