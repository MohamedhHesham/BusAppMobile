import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;         // Firestore document ID
  final String paymentID;     // internal payment ID
  final double amount;     // payment amount
  final DateTime paymentDate; // date of payment
  final String status;     // e.g. "pending", "completed", "failed"
  final String ticketID;      // FK to ticket

  Payment({
    required this.id,
    required this.paymentID,
    required this.amount,
    required this.paymentDate,
    required this.status,
    required this.ticketID,
  });

  // Firestore → Payment
  factory Payment.fromFirestore(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      paymentID: data['paymentID'] ?? 0,
      amount: (data['amount'] ?? 0).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      ticketID: data['ticketID'] ?? 0,
    );
  }

  // Payment → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'paymentID': paymentID,
      'amount': amount,
      'paymentDate': paymentDate,
      'status': status,
      'ticketID': ticketID,
    };
  }
}
