class Bus {
  final String id;
  final String busNumber;
  final int capacity;
  final String type;
  final String imageUrl;
  final double rating;

  Bus({
    required this.id,
    required this.busNumber,
    required this.capacity,
    required this.type,
    required this.imageUrl,
    required this.rating,
  });

  // Convert Firestore doc → Bus
  factory Bus.fromFirestore(Map<String, dynamic> data, String id) {
    return Bus(
      id: id,
      busNumber: data['busNumber'] ?? '',
      capacity: data['capacity'] ?? 0,
      type: data['type'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
    );
  }

  // Convert Bus → Firestore doc
  Map<String, dynamic> toFirestore() {
    return {
      'busNumber': busNumber,
      'capacity': capacity,
      'type': type,
      'imageUrl': imageUrl,
      'rating': rating,
    };
  }
}
