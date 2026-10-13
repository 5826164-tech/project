import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';
import '../models/history_model.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  /// Upload image to backend storage and receive public URL.
  static Future<String> uploadImage(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await imageFile.readAsBytes(),
        filename: imageFile.name,
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return data['url'] ?? '';
      } else {
        throw ApiException('Failed to upload image. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image to API: $e');
      return '';
    }
  }

  /// Upload image and get disease prediction.
  static Future<PredictionResult> predictDisease(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        await imageFile.readAsBytes(),
        filename: imageFile.name,
      ));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return PredictionResult.fromJson(json.decode(responseData));
      } else {
        throw ApiException('Failed to predict disease. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error predicting disease: $e');
    }
  }

  /// Save detection to cloud/local database via API.
  static Future<void> saveHistory(DetectionHistory history) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(history.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException('Failed to save history. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error saving history: $e');
    }
  }

  /// Fetch user history from cloud/local database.
  static Future<List<DetectionHistory>> getHistory(String uid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/history/$uid'));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => DetectionHistory.fromJson(item)).toList();
      } else {
        throw ApiException('Failed to fetch history. Server responded with ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('Error fetching history: $e');
    }
  }

  /// Fetch active database status (MongoDB Atlas, Firebase, or SQLite).
  static Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/db/status'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'active_database': 'unknown'};
    } catch (e) {
      return {'active_database': 'offline'};
    }
  }
}
