import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/prediction_model.dart';
import '../models/history_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

enum DetectionState { idle, loading, success, error }

class DetectionProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  DetectionState _state = DetectionState.idle;
  String _errorMessage = '';
  PredictionResult? _currentResult;
  List<DetectionHistory> _history = [];

  DetectionState get state => _state;
  String get errorMessage => _errorMessage;
  PredictionResult? get currentResult => _currentResult;
  List<DetectionHistory> get history => _history;

  Future<void> predictFromImage(XFile image, String uid) async {
    _state = DetectionState.loading;
    notifyListeners();
    
    try {
      _currentResult = await ApiService.predictDisease(image);
      _state = DetectionState.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = DetectionState.error;
      notifyListeners();
    }
  }

  Future<void> saveDetection(XFile image, String uid) async {
    if (_currentResult == null) return;
    try {
      String imageUrl = await _storageService.uploadImage(image, uid);
      
      DetectionHistory newHistory = DetectionHistory(
        id: const Uuid().v4(),
        uid: uid,
        imageUrl: imageUrl,
        plantName: _currentResult!.plantName,
        diseaseName: _currentResult!.diseaseName,
        confidence: _currentResult!.confidence,
        isHealthy: _currentResult!.isHealthy,
        timestamp: DateTime.now(),
        managementTips: _currentResult!.diseaseInfo?.management ?? [],
      );

      await ApiService.saveHistory(newHistory);
      _history.insert(0, newHistory);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving detection: $e');
    }
  }

  Future<void> loadHistory(String uid) async {
    _state = DetectionState.loading;
    notifyListeners();
    try {
      _history = await ApiService.getHistory(uid);
      _state = DetectionState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = DetectionState.error;
      notifyListeners();
    }
  }
}
