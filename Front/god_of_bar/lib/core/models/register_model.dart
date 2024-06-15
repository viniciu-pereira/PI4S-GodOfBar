class RegisterModel {
  final String id;
  final String temperature;
  final String humidity;
  final String timestamp;

  RegisterModel({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      id: json['id'] as String,
      temperature: json['temperature'] as String,
      humidity: json['humidity'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}
