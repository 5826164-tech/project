/// Represents a past plant disease detection record.
class DetectionHistory {
  final String id;
  final String uid;
  final String imageUrl;
  final String plantName;
  final String diseaseName;
  final double confidence;
  final bool isHealthy;
  final DateTime timestamp;
  final List<String> managementTips;

  DetectionHistory({
    required this.id,
    required this.uid,
    required this.imageUrl,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
    required this.timestamp,
    required this.managementTips,
  });
  
  factory DetectionHistory.fromJson(Map<String, dynamic> json) {
    return DetectionHistory(
      id: json['id'] ?? '',
      uid: json['uid'] ?? '',
      imageUrl: json['image_url'] ?? '',
      plantName: json['plant_name'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isHealthy: json['is_healthy'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      managementTips: List<String>.from(json['management_tips'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'image_url': imageUrl,
      'plant_name': plantName,
      'disease_name': diseaseName,
      'confidence': confidence,
      'is_healthy': isHealthy,
      'timestamp': timestamp.toIso8601String(),
      'management_tips': managementTips,
    };
  }
}
