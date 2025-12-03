// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AdminService {
  static const String _baseUrl = 'http://your-backend-api.com/api/admin';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  String? _authToken;

  // Set authentication token (call this after login)
  void setAuthToken(String token) {
    _authToken = token;
    _headers['Authorization'] = 'Bearer $token';
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/stats'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get recent activities
  Future<List<dynamic>> getRecentActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/activities/recent'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load recent activities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get system status
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load system status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get notifications
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generate report
  Future<String> generateReport(String reportType, DateTime fromDate, DateTime toDate) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reports/generate'),
        headers: _headers,
        body: json.encode({
          'report_type': reportType,
          'from_date': fromDate.toIso8601String(),
          'to_date': toDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['report_url'] ?? 'Report generated successfully';
      } else {
        throw Exception('Failed to generate report');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get admin profile
  Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load admin profile');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Clear auth token
        _authToken = null;
        _headers.remove('Authorization');
      }
    } catch (e) {
      // Even if API call fails, clear local token
      _authToken = null;
      _headers.remove('Authorization');
    }
  }
}