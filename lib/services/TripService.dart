import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Trip.dart';

class TripService {
  final CollectionReference trips =
  FirebaseFirestore.instance.collection('trips');

  // Add a new trip
  Future<void> addTrip(Trip trip) async {
    await trips.add(trip.toFirestore());
  }

  // Get all trips
  Future<List<Trip>> getTrips() async {
    final snapshot = await trips.get();
    return snapshot.docs
        .map((doc) => Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Stream trips (real-time updates)
  Stream<List<Trip>> streamTrips() {
    return trips.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Get trips by source/destination
  Future<List<Trip>> searchTrips(String source, String destination) async {
    final snapshot = await trips
        .where('source', isEqualTo: source)
        .where('destination', isEqualTo: destination)
        .get();
    return snapshot.docs
        .map((doc) => Trip.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Update available seats
  Future<void> updateSeats(String tripId, int newSeats) async {
    await trips.doc(tripId).update({'availableSeats': newSeats});
  }
}
