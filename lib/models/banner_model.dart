class Banner {
  final String title;
  final String description;
  final String spotImage;
  final String spotImageUrl;
  final String address;
  final double latitude;
  final double longitude;

  Banner({
    required this.title,
    required this.description,
    required this.spotImage,
    required this.spotImageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // Create Banner from JSON
  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      spotImage: json['spot_image'] ?? '',
      spotImageUrl: json['spot_image_url'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
