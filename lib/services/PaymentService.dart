import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Payment.dart';

class PaymentService {
  final CollectionReference payments =
  FirebaseFirestore.instance.collection('payments');

  // Record a new payment
  Future<void> addPayment(Payment payment) async {
    await payments.add(payment.toFirestore());
  }

  // Get all payments for a ticket
  Future<List<Payment>> getPaymentsForTicket(int ticketID) async {
    final snapshot = await payments.where('ticketID', isEqualTo: ticketID).get();
    return snapshot.docs
        .map((doc) => Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Stream payments for real-time updates
  Stream<List<Payment>> streamPayments() {
    return payments.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Payment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Update payment status
  Future<void> updateStatus(String paymentDocId, String newStatus) async {
    await payments.doc(paymentDocId).update({'status': newStatus});
  }
}
