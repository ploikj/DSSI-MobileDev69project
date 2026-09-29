class Equipment {
  final int id;
  final String name;
  final String category;
  final String categoryDisplay;
  final String? modelNumber;
  final String description;
  final String imageUrl;
  final int totalQuantity;
  final int availableQuantity;
  final String pickupLocation;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryDisplay,
    this.modelNumber,
    required this.description,
    required this.imageUrl,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.pickupLocation,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'laptop',
      categoryDisplay: json['category_display'] as String? ?? '',
      modelNumber: json['model_number'] as String?,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      totalQuantity: json['total_quantity'] as int? ?? 0,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      pickupLocation: json['pickup_location'] as String? ?? 'ห้องบริการไอที',
    );
  }

  bool get isAvailable => availableQuantity > 0;
}
