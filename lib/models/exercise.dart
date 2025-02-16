class Exercise {
  final String name;
  final int targetOutput; // Target value for the exercise (e.g., 500 meters)
  final String unit; // Unit of measurement (e.g., "meters", "seconds")

  Exercise({
    required this.name,
    required this.targetOutput,
    required this.unit,
  });

  // Factory method to create an Exercise from JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      targetOutput: json['target'] ?? 0, // Use 'target' from JSON, default to 0 if null
      unit: json['unit'] ?? 'repetitions', // Default to 'repetitions' if unit is null
    );
  }

  // Convert Exercise to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'targetOutput': targetOutput,
      'unit': unit,
    };
  }
}