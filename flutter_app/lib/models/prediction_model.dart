/// Model representing the AI prediction result from the backend API.
class PredictionResult {
  final String classLabel;
  final double confidence;
  final String plantName;
  final String diseaseName;
  final bool isHealthy;
  final DiseaseInfo? diseaseInfo;
  final bool isMock;

  PredictionResult({
    required this.classLabel,
    required this.confidence,
    required this.plantName,
    required this.diseaseName,
    required this.isHealthy,
    this.diseaseInfo,
    this.isMock = false,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      classLabel: json['class_label'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      plantName: json['plant_name'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      isHealthy: json['is_healthy'] ?? false,
      diseaseInfo: json['disease_info'] != null
          ? DiseaseInfo.fromJson(json['disease_info'])
          : null,
      isMock: json['mock'] ?? false,
    );
  }
}

class DiseaseInfo {
  final String plant;
  final String disease;
  final String description;
  final List<String> symptoms;
  final String causes;
  final List<String> management;
  final String severity;

  DiseaseInfo({
    required this.plant,
    required this.disease,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.management,
    required this.severity,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      plant: json['plant'] ?? '',
      disease: json['disease'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: json['causes'] ?? '',
      management: List<String>.from(json['management'] ?? []),
      severity: json['severity'] ?? 'Unknown',
    );
  }
}
