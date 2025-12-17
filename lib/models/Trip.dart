import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;            // Firestore document ID
  final String source;        // starting point
  final String destination;   // ending point
  final DateTime date;        // trip date
  final String time;          // trip time
  final int availableSeats;   // remaining seats
  final String busID;            // linked bus ID

  Trip({
    required this.id,
    required this.source,
    required this.destination,
    required this.date,
    required this.time,
    required this.availableSeats,
    required this.busID,
  });

  // Firestore → Trip
  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      source: data['source'] ?? '',
      destination: data['destination'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      availableSeats: data['availableSeats'] ?? 0,
      busID: data['busID'] ?? '',
    );
  }

  // Trip → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'source': source,
      'destination': destination,
      'date': date,
      'time': time,
      'availableSeats': availableSeats,
      'busID': busID,
    };
  }
}
