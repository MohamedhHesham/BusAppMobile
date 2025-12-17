import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Bus.dart';

class BusService {
  final CollectionReference buses =
  FirebaseFirestore.instance.collection('buses');

  // Add a new bus
  Future<void>addBus(Bus bus) async {
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
    return buses.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Update bus rating
  Future<void> updateRating(String busId, double newRating) async {
    await buses.doc(busId).update({'rating': newRating});
  }

  // Delete a bus
  Future<void> deleteBus(String busId) async {
    await buses.doc(busId).delete();
  }
}
