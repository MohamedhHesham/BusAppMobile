import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Ticket.dart';

class TicketService {
  final _db = FirebaseFirestore.instance;

  // Add a new ticket
  Future<void> bookTicket(Ticket ticket) async {
    await _db.collection('tickets').add(ticket.toFirestore());
  }

  // Get all tickets for a specific user
  Future<List<Ticket>> getTicketsByUser(String userId) async {
    try {
      final snapshot = await _db
          .collection('tickets')
          .where('userID', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final tickets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Ticket.fromFirestore(data, doc.id);
      }).toList();

      // Sort by paymentDate (newest first)
      tickets.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      return tickets;
    } catch (e) {
      print('Error fetching tickets: $e');
      rethrow;
    }
  }

  // Stream tickets for real-time updates
  Stream<List<Ticket>> streamTicketsByUser(String userId) {
    return _db
        .collection('tickets')
        .where('userID', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Ticket.fromFirestore(data, doc.id);
      }).toList();

      tickets.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return tickets;
    });
  }

  // Cancel a ticket
  Future<Map<String, dynamic>> cancelTicket({
    required String userId,
    required String tripId,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Find active ticket
      final ticketsSnapshot = await _db
          .collection('tickets')
          .where('userID', isEqualTo: userId)
          .where('tripID', isEqualTo: tripId)
          .where('status', isEqualTo: 'booked')
          .get();

      if (ticketsSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No active ticket found for this trip'
        };
      }
      final ticketDoc = ticketsSnapshot.docs.first;
      final ticketData = ticketDoc.data();
      final paymentID = ticketData['paymentID'];

      // 2. Update ticket status
      batch.update(
        _db.collection('tickets').doc(ticketDoc.id),
        {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        },
      );

      if (paymentID != null) {
        final paymentSnapshot = await _db
            .collection('payments')
            .where('paymentID', isEqualTo: paymentID)
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          batch.update(
            _db.collection('payments').doc(paymentSnapshot.docs.first.id),
            {
              'status': 'refunded',
              'refundedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      // 4. Increment available seats in trip
      final tripDoc = await _db.collection('trips').doc(tripId).get();
      if (tripDoc.exists) {
        final currentSeats = tripDoc.data()?['availableSeats'] ?? 0;
        batch.update(
          _db.collection('trips').doc(tripId),
          {
            'availableSeats': currentSeats + 1,
          },
        );
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Ticket cancelled successfully. Seat released.'
      };
    } catch (e) {
      print('Error cancelling ticket: $e');
      return {
        'success': false,
        'message': 'Failed to cancel ticket: $e'
      };
    }
  }



  Future<bool> canCancelTicket(String tripId) async {
    try {
      final tripDoc = await _db.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return false;

      final tripDate = (tripDoc.data()?['date'] as Timestamp).toDate();
      final now = DateTime.now();

      // Allow cancellation if today is before trip date
      if (now.isBefore(DateTime(tripDate.year, tripDate.month, tripDate.day))) {
        return true;
      }

      // If same day, allow cancellation only if > 2 hours before
      final hoursDifference = tripDate.difference(now).inHours;
      return hoursDifference > 2;
    } catch (e) {
      print('Error checking cancellation eligibility: $e');
      return false;
    }
  }

  // Check if ticket is already cancelled
  Future<bool> isTicketCancelled(String userId, String tripId) async {
    try {
      final ticketsSnapshot = await _db
          .collection('tickets')
          .where('userID', isEqualTo: userId)
          .where('tripID', isEqualTo: tripId)
          .get();

      if (ticketsSnapshot.docs.isEmpty) return false;

      final status = ticketsSnapshot.docs.first.data()['status'] ?? '';
      return status == 'cancelled';
    } catch (e) {
      print('Error checking ticket status: $e');
      return false;
    }
  }

  // Mark a ticket as rated
  Future<bool> markTicketAsRated(String ticketId) async {
    try {
      await _db.collection('tickets').doc(ticketId).update({
        'isRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking ticket as rated: $e');
      return false;
    }
  }

  // Get unrated tickets for a user (useful for prompting reviews)
  Future<List<Ticket>> getUnratedTicketsByUser(String userId) async {
    try {
      final snapshot = await _db
          .collection('tickets')
          .where('userID', isEqualTo: userId)
          .where('status', isEqualTo: 'booked')
          .where('isRated', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final tickets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Ticket.fromFirestore(data, doc.id);
      }).toList();

      // Sort by paymentDate (oldest first for unrated)
      tickets.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

      return tickets;
    } catch (e) {
      print('Error fetching unrated tickets: $e');
      return [];
    }
  }

  // Get completed tickets that can be rated (trip date has passed)
  Future<List<Ticket>> getCompletedUnratedTickets(String userId) async {
    try {
      final snapshot = await _db
          .collection('tickets')
          .where('userID', isEqualTo: userId)
          .where('status', isEqualTo: 'booked')
          .where('isRated', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return [];

      final tickets = snapshot.docs.map((doc) {
        final data = doc.data();
        return Ticket.fromFirestore(data, doc.id);
      }).toList();

      // Filter tickets where trip date has passed
      final completedTickets = <Ticket>[];
      final now = DateTime.now();

      for (final ticket in tickets) {
        try {
          final tripDoc = await _db.collection('trips').doc(ticket.tripID).get();
          if (tripDoc.exists) {
            final tripDate = (tripDoc.data()?['date'] as Timestamp).toDate();
            if (tripDate.isBefore(now)) {
              completedTickets.add(ticket);
            }
          }
        } catch (e) {
          print('Error checking trip date for ticket ${ticket.id}: $e');
        }
      }

      // Sort by paymentDate (oldest first)
      completedTickets.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));

      return completedTickets;
    } catch (e) {
      print('Error fetching completed unrated tickets: $e');
      return [];
    }
  }

  // Check if a specific ticket has been rated
  Future<bool> isTicketRated(String ticketId) async {
    try {
      final ticketDoc = await _db.collection('tickets').doc(ticketId).get();
      if (!ticketDoc.exists) return false;

      return ticketDoc.data()?['isRated'] ?? false;
    } catch (e) {
      print('Error checking if ticket is rated: $e');
      return false;
    }
  }
}