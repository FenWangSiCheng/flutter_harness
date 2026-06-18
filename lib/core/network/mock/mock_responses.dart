import 'dart:convert';
import 'package:flutter/services.dart';

class MockResponses {
  static Future<List<Map<String, dynamic>>> loadUserList() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/mock/users.json',
      );
      final List<dynamic> jsonList = jsonDecode(response);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final users = await loadUserList();
    try {
      return users.firstWhere((user) => user['id'] == userId);
    } catch (e) {
      return null;
    }
  }
}
