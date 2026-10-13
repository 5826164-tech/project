class Disease {
  final String name;
  final String description;
  final List<String> symptoms;
  final String treatment;

  Disease({
    required this.name,
    required this.description,
    required this.symptoms,
    required this.treatment,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatment: json['treatment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'symptoms': symptoms,
      'treatment': treatment,
    };
  }
}
