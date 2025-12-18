import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Bus.dart';

class BusService {
  final CollectionReference buses =
  FirebaseFirestore.instance.collection('buses');

  // Add a new bus
  Future<void> addBus(Bus bus) async {
    await buses.add(bus.toFirestore());
  }

  // Get all buses once
  Future<List<Bus>> getBuses() async {
    final snapshot = await buses.get();
    return snapshot.docs
        .map((doc) => Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Stream buses (real-time updates)
  Stream<List<Bus>> streamBuses() {
    return buses.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Add a rating to a bus (calculates new average)
  Future<void> addRating(String busId, double newRating) async {
    try {
      final busDoc = await buses.doc(busId).get();

      if (!busDoc.exists) {
        throw Exception('Bus not found');
      }

      final data = busDoc.data() as Map<String, dynamic>;
      final currentRating = (data['rating'] ?? 0).toDouble();
      final currentCount = data['numberOfRatings'] ?? 0;

      // Calculate new average rating
      final totalRating = (currentRating * currentCount) + newRating;
      final newCount = currentCount + 1;
      final newAverage = totalRating / newCount;

      await buses.doc(busId).update({
        'rating': newAverage,
        'numberOfRatings': newCount,
      });
    } catch (e) {
      throw Exception('Failed to add rating: $e');
    }
  }

  // Update bus rating (legacy method - use addRating instead)
  @deprecated
  Future<void> updateRating(String busId, double newRating) async {
    await buses.doc(busId).update({'rating': newRating});
  }

  // Get a single bus by ID
  Future<Bus?> getBusById(String busId) async {
    try {
      final doc = await buses.doc(busId).get();
      if (doc.exists) {
        return Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get bus: $e');
    }
  }

  // Delete a bus
  Future<void> deleteBus(String busId) async {
    await buses.doc(busId).delete();
  }

  // Reset ratings for a bus (admin function)
  Future<void> resetRatings(String busId) async {
    await buses.doc(busId).update({
      'rating': 0.0,
      'numberOfRatings': 0,
    });
  }
}