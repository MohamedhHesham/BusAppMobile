import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String id;          // Firestore document ID
  final String ticketID;    // internal ticket ID
  final String status;
  final double amount;      // ticket price
  final DateTime paymentDate; // when payment was made
  final String userID;      // FK to user
  final String tripID;      // FK to trip
  final String paymentID;
  final bool isRated;       // whether user has rated this trip

  Ticket({
    required this.id,
    required this.ticketID,
    required this.status,
    required this.amount,
    required this.paymentDate,
    required this.userID,
    required this.tripID,
    required this.paymentID,
    this.isRated = false,   // default to false
  });

  // Firestore → Ticket
  factory Ticket.fromFirestore(Map<String, dynamic> data, String id) {
    return Ticket(
      id: id,
      ticketID: data['ticketID'] ?? '',
      status: data['status'] ?? 'booked',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      userID: data['userID'] ?? '',
      tripID: data['tripID'] ?? '',
      paymentID: data['paymentID'] ?? '',
      isRated: data['isRated'] ?? false, // default to false if not present
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
      'isRated': isRated,
    };
  }

  // Helper method to create a copy with updated isRated status
  Ticket copyWith({
    String? id,
    String? ticketID,
    String? status,
    double? amount,
    DateTime? paymentDate,
    String? userID,
    String? tripID,
    String? paymentID,
    bool? isRated,
  }) {
    return Ticket(
      id: id ?? this.id,
      ticketID: ticketID ?? this.ticketID,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      userID: userID ?? this.userID,
      tripID: tripID ?? this.tripID,
      paymentID: paymentID ?? this.paymentID,
      isRated: isRated ?? this.isRated,
    );
  }
}