import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;          // Firestore document ID
  final String ticketID;       // internal ticket ID
  final String status;
  final double amount;      // ticket price
  final DateTime paymentDate; // when payment was made
  final String userID;         // FK to user
  final String tripID;         // FK to trip
  final String paymentID;
  Ticket({
    required this.id,
    required this.ticketID,
    required this.status,
    required this.amount,
    required this.paymentDate,
    required this.userID,
    required this.tripID,
    required this.paymentID,
  });

  // Firestore → Ticket
  factory Ticket.fromFirestore(Map<String, dynamic> data, String id) {
    return Ticket(
      id: id,
      ticketID: data['ticketID'] ?? 0,
      status: data['status'] ?? 'booked',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      userID: data['userID'] ?? 0,
      tripID: data['tripID'] ?? 0,
      paymentID: data['paymentID'] ?? 0,
    );
  }

  // Ticket → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ticketID': ticketID,
      'status': status,
      'amount': amount,
      'paymentDate': paymentDate,
      'userID': userID,
      'tripID': tripID,
      'paymentID': paymentID,
    };
  }
}
