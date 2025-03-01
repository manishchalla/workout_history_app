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
    if (!json.containsKey('name') || !json.containsKey('target') || !json.containsKey('unit')) {
      print("⚠️ Warning: Malformed Exercise JSON -> $json");
    }

    return Exercise(
      name: json['name'] as String? ?? 'Unknown Exercise',
      targetOutput: json['target'] as int? ?? 0, // Use 'target' from JSON
      unit: json['unit'] as String? ?? 'repetitions', // Default to 'repetitions' if null
    );
  }

  // Convert Exercise to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target': targetOutput, // Ensure key consistency
      'unit': unit,
    };
  }
}