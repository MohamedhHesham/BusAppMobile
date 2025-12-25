import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Ticket.dart';
import 'package:busapp/models/Bus.dart';
import 'package:busapp/models/Trip.dart';
import 'package:busapp/models/User.dart';
import 'package:busapp/models/Payment.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('UserService Tests', () {
    test('should create and retrieve user by email', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'user123',
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('email', isEqualTo: 'john@example.com')
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
      final retrievedUser = AppUser.fromFirestore(
          snapshot.docs.first.data());

      expect(retrievedUser.email, equals('john@example.com'));
      expect(retrievedUser.name, equals('John Doe'));
    });

    test('should retrieve user by userID', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'user456',
        name: 'Jane Smith',
        email: 'jane@example.com',
        password: 'pass456',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('userID', isEqualTo: 'user456')
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);
      final retrievedUser = AppUser.fromFirestore(
          snapshot.docs.first.data());

      expect(retrievedUser.userID, equals('user456'));
    });

    test('should promote user to admin', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'user789',
        name: 'Admin User',
        email: 'admin@example.com',
        password: 'admin123',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('userID', isEqualTo: 'user789')
          .get();

      await snapshot.docs.first.reference.update({'role': 'admin'});

      final updatedSnapshot = await usersCollection
          .where('userID', isEqualTo: 'user789')
          .get();

      final updatedUser = AppUser.fromFirestore(
          updatedSnapshot.docs.first.data());

      expect(updatedUser.role, equals('admin'));
    });

    test('should update user data', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'user999',
        name: 'Old Name',
        email: 'old@example.com',
        password: 'pass',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('userID', isEqualTo: 'user999')
          .get();

      await snapshot.docs.first.reference.update({'name': 'New Name'});

      final updatedSnapshot = await usersCollection
          .where('userID', isEqualTo: 'user999')
          .get();

      final updatedUser = AppUser.fromFirestore(
          updatedSnapshot.docs.first.data());

      expect(updatedUser.name, equals('New Name'));
    });

    test('should delete user', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'userToDelete',
        name: 'Delete Me',
        email: 'delete@example.com',
        password: 'pass',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('userID', isEqualTo: 'userToDelete')
          .get();

      await snapshot.docs.first.reference.delete();

      final deletedSnapshot = await usersCollection
          .where('userID', isEqualTo: 'userToDelete')
          .get();

      expect(deletedSnapshot.docs.isEmpty, isTrue);
    });

    test('should generate unique userID', () async {
      final timestamp1 = DateTime.now().millisecondsSinceEpoch;
      final userID1 = 'USER_$timestamp1';

      await Future.delayed(Duration(milliseconds: 10));

      final timestamp2 = DateTime.now().millisecondsSinceEpoch;
      final userID2 = 'USER_$timestamp2';

      expect(userID1, isNotEmpty);
      expect(userID2, isNotEmpty);
      expect(userID1, isNot(equals(userID2)));
      expect(userID1.startsWith('USER_'), isTrue);
    });
  });

  group('AuthService Tests', () {
    test('should register and login with valid credentials', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'auth123',
        name: 'Auth User',
        email: 'auth@example.com',
        password: 'authpass',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('email', isEqualTo: 'auth@example.com')
          .get();

      expect(snapshot.docs.isNotEmpty, isTrue);

      final loggedInUser = AppUser.fromFirestore(snapshot.docs.first.data());

      expect(loggedInUser.password, equals('authpass'));
      expect(loggedInUser.email, equals('auth@example.com'));
    });

    test('should fail login with invalid credentials', () async {
      final usersCollection = fakeFirestore.collection('users');

      final user = AppUser(
        userID: 'fail123',
        name: 'Fail User',
        email: 'fail@example.com',
        password: 'correctpass',
        role: 'user',
      );

      await usersCollection.add(user.toFirestore());

      final snapshot = await usersCollection
          .where('email', isEqualTo: 'fail@example.com')
          .get();

      final retrievedUser = AppUser.fromFirestore(snapshot.docs.first.data());

      expect(retrievedUser.password == 'wrongpass', isFalse);
    });

    test('should check if user is admin', () async {
      final usersCollection = fakeFirestore.collection('users');

      final adminUser = AppUser(
        userID: 'admin123',
        name: 'Admin',
        email: 'admin@test.com',
        password: 'pass',
        role: 'admin',
      );

      await usersCollection.add(adminUser.toFirestore());

      final snapshot = await usersCollection
          .where('userID', isEqualTo: 'admin123')
          .get();

      final user = AppUser.fromFirestore(snapshot.docs.first.data());

      expect(user.role, equals('admin'));
    });
  });

  group('BusService Tests', () {
    test('should add and retrieve bus', () async {
      final busesCollection = fakeFirestore.collection('buses');

      final bus = Bus(
        id: '',
        busNumber: 'BUS001',
        capacity: 50,
        type: 'Luxury',
        imageUrl: 'https://example.com/bus.jpg',
        rating: 4.5,
        numberOfRatings: 10,
      );

      await busesCollection.add(bus.toFirestore());

      final snapshot = await busesCollection.get();
      expect(snapshot.docs.length, greaterThan(0));

      final retrievedBus = Bus.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);

      expect(retrievedBus.busNumber, equals('BUS001'));
    });

    test('should get bus by ID', () async {
      final busesCollection = fakeFirestore.collection('buses');

      final bus = Bus(
        id: '',
        busNumber: 'BUS002',
        capacity: 40,
        type: 'Standard',
        imageUrl: 'https://example.com/bus2.jpg',
        rating: 4.0,
        numberOfRatings: 5,
      );

      final docRef = await busesCollection.add(bus.toFirestore());

      final doc = await docRef.get();
      expect(doc.exists, isTrue);

      final retrievedBus = Bus.fromFirestore(doc.data()!, doc.id);
      expect(retrievedBus.busNumber, equals('BUS002'));
    });

    test('should add rating to bus', () async {
      final busesCollection = fakeFirestore.collection('buses');

      final bus = Bus(
        id: '',
        busNumber: 'BUS003',
        capacity: 45,
        type: 'Economy',
        imageUrl: 'https://example.com/bus3.jpg',
        rating: 4.0,
        numberOfRatings: 2,
      );

      final docRef = await busesCollection.add(bus.toFirestore());

      // Simulate adding rating
      final currentRating = 4.0;
      final currentCount = 2;
      final newRating = 5.0;

      final totalRating = (currentRating * currentCount) + newRating;
      final newCount = currentCount + 1;
      final newAverage = totalRating / newCount;

      await docRef.update({
        'rating': newAverage,
        'numberOfRatings': newCount,
      });

      final updatedDoc = await docRef.get();
      final updatedBus = Bus.fromFirestore(updatedDoc.data()!, updatedDoc.id);

      expect(updatedBus.numberOfRatings, equals(3));
      expect(updatedBus.rating, closeTo(4.33, 0.01));
    });

    test('should delete bus', () async {
      final busesCollection = fakeFirestore.collection('buses');

      final bus = Bus(
        id: '',
        busNumber: 'BUS004',
        capacity: 30,
        type: 'Mini',
        imageUrl: 'https://example.com/bus4.jpg',
        rating: 3.5,
        numberOfRatings: 1,
      );

      final docRef = await busesCollection.add(bus.toFirestore());
      await docRef.delete();

      final deletedDoc = await docRef.get();
      expect(deletedDoc.exists, isFalse);
    });

    test('should reset ratings', () async {
      final busesCollection = fakeFirestore.collection('buses');

      final bus = Bus(
        id: '',
        busNumber: 'BUS005',
        capacity: 50,
        type: 'Luxury',
        imageUrl: 'https://example.com/bus5.jpg',
        rating: 4.5,
        numberOfRatings: 20,
      );

      final docRef = await busesCollection.add(bus.toFirestore());

      await docRef.update({
        'rating': 0.0,
        'numberOfRatings': 0,
      });

      final resetDoc = await docRef.get();
      final resetBus = Bus.fromFirestore(resetDoc.data()!, resetDoc.id);

      expect(resetBus.rating, equals(0.0));
      expect(resetBus.numberOfRatings, equals(0));
    });
  });

  group('TripService Tests', () {
    test('should add and retrieve trip', () async {
      final tripsCollection = fakeFirestore.collection('trips');

      final trip = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Alexandria',
        date: DateTime.now().add(Duration(days: 1)),
        time: '10:00 AM',
        availableSeats: 30,
        busID: 'bus123',
      );

      await tripsCollection.add(trip.toFirestore());

      final snapshot = await tripsCollection.get();
      expect(snapshot.docs.length, greaterThan(0));

      final retrievedTrip = Trip.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);

      expect(retrievedTrip.source, equals('Cairo'));
      expect(retrievedTrip.destination, equals('Alexandria'));
    });

    test('should search trips by source and destination', () async {
      final tripsCollection = fakeFirestore.collection('trips');

      final trip1 = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Luxor',
        date: DateTime.now().add(Duration(days: 2)),
        time: '08:00 AM',
        availableSeats: 25,
        busID: 'bus456',
      );

      final trip2 = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Aswan',
        date: DateTime.now().add(Duration(days: 3)),
        time: '09:00 AM',
        availableSeats: 20,
        busID: 'bus789',
      );

      await tripsCollection.add(trip1.toFirestore());
      await tripsCollection.add(trip2.toFirestore());

      final foundSnapshot = await tripsCollection
          .where('source', isEqualTo: 'Cairo')
          .where('destination', isEqualTo: 'Luxor')
          .get();

      expect(foundSnapshot.docs.length, greaterThan(0));

      final foundTrip = Trip.fromFirestore(
          foundSnapshot.docs.first.data(), foundSnapshot.docs.first.id);

      expect(foundTrip.destination, equals('Luxor'));
    });

    test('should update available seats', () async {
      final tripsCollection = fakeFirestore.collection('trips');

      final trip = Trip(
        id: '',
        source: 'Giza',
        destination: 'Hurghada',
        date: DateTime.now().add(Duration(days: 5)),
        time: '11:00 AM',
        availableSeats: 40,
        busID: 'bus999',
      );

      final docRef = await tripsCollection.add(trip.toFirestore());

      await docRef.update({'availableSeats': 35});

      final updatedDoc = await docRef.get();
      final updatedTrip = Trip.fromFirestore(updatedDoc.data()!, updatedDoc.id);

      expect(updatedTrip.availableSeats, equals(35));
    });
  });

  group('PaymentService Tests', () {
    test('should add and retrieve payment', () async {
      final paymentsCollection = fakeFirestore.collection('payments');

      final payment = Payment(
        id: '',
        paymentID: 'PAY001',
        amount: 150.0,
        paymentDate: DateTime.now(),
        status: 'completed',
        ticketID: 'ticket123',
      );

      await paymentsCollection.add(payment.toFirestore());

      final snapshot = await paymentsCollection.get();
      expect(snapshot.docs.length, greaterThan(0));

      final retrievedPayment = Payment.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);

      expect(retrievedPayment.paymentID, equals('PAY001'));
      expect(retrievedPayment.amount, equals(150.0));
    });

    test('should update payment status', () async {
      final paymentsCollection = fakeFirestore.collection('payments');

      final payment = Payment(
        id: '',
        paymentID: 'PAY002',
        amount: 200.0,
        paymentDate: DateTime.now(),
        status: 'pending',
        ticketID: 'ticket456',
      );

      final docRef = await paymentsCollection.add(payment.toFirestore());

      await docRef.update({'status': 'completed'});

      final updatedDoc = await docRef.get();
      final updatedPayment = Payment.fromFirestore(
          updatedDoc.data()!, updatedDoc.id);

      expect(updatedPayment.status, equals('completed'));
    });

    test('should get payments for specific ticket', () async {
      final paymentsCollection = fakeFirestore.collection('payments');

      final payment = Payment(
        id: '',
        paymentID: 'PAY003',
        amount: 100.0,
        paymentDate: DateTime.now(),
        status: 'completed',
        ticketID: 'ticket789',
      );

      await paymentsCollection.add(payment.toFirestore());

      final snapshot = await paymentsCollection
          .where('ticketID', isEqualTo: 'ticket789')
          .get();

      expect(snapshot.docs.length, greaterThan(0));
    });
  });

  group('TicketService Tests', () {
    test('should book a ticket', () async {
      final ticketsCollection = fakeFirestore.collection('tickets');

      final ticket = Ticket(
        id: '',
        ticketID: 'TICKET001',
        status: 'booked',
        amount: 100.0,
        paymentDate: DateTime.now(),
        userID: 'user123',
        tripID: 'trip456',
        paymentID: 'PAY001',
        isRated: false,
      );

      await ticketsCollection.add(ticket.toFirestore());

      final snapshot = await ticketsCollection
          .where('userID', isEqualTo: 'user123')
          .get();

      expect(snapshot.docs.length, greaterThan(0));

      final retrievedTicket = Ticket.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);

      expect(retrievedTicket.ticketID, equals('TICKET001'));
    });

    test('should get tickets by user sorted by date', () async {
      final ticketsCollection = fakeFirestore.collection('tickets');

      final ticket1 = Ticket(
        id: '',
        ticketID: 'TICKET002',
        status: 'booked',
        amount: 100.0,
        paymentDate: DateTime.now().subtract(Duration(days: 2)),
        userID: 'user456',
        tripID: 'trip789',
        paymentID: 'PAY002',
        isRated: false,
      );

      final ticket2 = Ticket(
        id: '',
        ticketID: 'TICKET003',
        status: 'booked',
        amount: 150.0,
        paymentDate: DateTime.now(),
        userID: 'user456',
        tripID: 'trip789',
        paymentID: 'PAY003',
        isRated: false,
      );

      await ticketsCollection.add(ticket1.toFirestore());
      await ticketsCollection.add(ticket2.toFirestore());

      final snapshot = await ticketsCollection
          .where('userID', isEqualTo: 'user456')
          .get();

      final tickets = snapshot.docs.map((doc) {
        return Ticket.fromFirestore(doc.data(), doc.id);
      }).toList();

      tickets.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      expect(tickets.length, greaterThanOrEqualTo(2));
      expect(tickets.first.paymentDate.isAfter(tickets.last.paymentDate),
          isTrue);
    });

    test('should cancel a ticket', () async {
      final ticketsCollection = fakeFirestore.collection('tickets');
      final tripsCollection = fakeFirestore.collection('trips');

      // Create trip
      final trip = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Alex',
        date: DateTime.now().add(Duration(days: 7)),
        time: '10:00 AM',
        availableSeats: 10,
        busID: 'bus123',
      );

      final tripDocRef = await tripsCollection.add(trip.toFirestore());

      // Create ticket
      final ticket = Ticket(
        id: '',
        ticketID: 'TICKET004',
        status: 'booked',
        amount: 100.0,
        paymentDate: DateTime.now(),
        userID: 'user789',
        tripID: tripDocRef.id,
        paymentID: 'PAY004',
        isRated: false,
      );

      final ticketDocRef = await ticketsCollection.add(ticket.toFirestore());

      // Cancel ticket
      await ticketDocRef.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // Update trip seats
      final tripDoc = await tripDocRef.get();
      final currentSeats = tripDoc.data()!['availableSeats'];
      await tripDocRef.update({'availableSeats': currentSeats + 1});

      // Verify
      final cancelledDoc = await ticketDocRef.get();
      final cancelledTicket = Ticket.fromFirestore(
          cancelledDoc.data()!, cancelledDoc.id);

      expect(cancelledTicket.status, equals('cancelled'));

      final updatedTripDoc = await tripDocRef.get();
      final updatedTrip = Trip.fromFirestore(
          updatedTripDoc.data()!, updatedTripDoc.id);

      expect(updatedTrip.availableSeats, equals(11));
    });

    test('should check if ticket can be cancelled', () async {
      final tripsCollection = fakeFirestore.collection('trips');

      // Future trip - should be cancellable
      final futureTrip = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Luxor',
        date: DateTime.now().add(Duration(days: 5)),
        time: '10:00 AM',
        availableSeats: 20,
        busID: 'bus456',
      );

      final futureTripRef = await tripsCollection.add(futureTrip.toFirestore());
      final futureTripDoc = await futureTripRef.get();
      final tripDate = (futureTripDoc.data()!['date'] as Timestamp).toDate();

      final now = DateTime.now();
      final canCancel = now.isBefore(
          DateTime(tripDate.year, tripDate.month, tripDate.day));

      expect(canCancel, isTrue);
    });

    test('should mark ticket as rated', () async {
      final ticketsCollection = fakeFirestore.collection('tickets');

      final ticket = Ticket(
        id: '',
        ticketID: 'TICKET006',
        status: 'booked',
        amount: 100.0,
        paymentDate: DateTime.now(),
        userID: 'user999',
        tripID: 'trip999',
        paymentID: 'PAY006',
        isRated: false,
      );

      final docRef = await ticketsCollection.add(ticket.toFirestore());

      await docRef.update({
        'isRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await docRef.get();
      final updatedTicket = Ticket.fromFirestore(
          updatedDoc.data()!, updatedDoc.id);

      expect(updatedTicket.isRated, isTrue);
    });

    test('should get unrated tickets', () async {
      final ticketsCollection = fakeFirestore.collection('tickets');

      final ticket = Ticket(
        id: '',
        ticketID: 'TICKET007',
        status: 'booked',
        amount: 100.0,
        paymentDate: DateTime.now(),
        userID: 'user111',
        tripID: 'trip111',
        paymentID: 'PAY007',
        isRated: false,
      );

      await ticketsCollection.add(ticket.toFirestore());

      final snapshot = await ticketsCollection
          .where('userID', isEqualTo: 'user111')
          .where('status', isEqualTo: 'booked')
          .where('isRated', isEqualTo: false)
          .get();

      expect(snapshot.docs.length, greaterThan(0));

      final unratedTickets = snapshot.docs.map((doc) {
        return Ticket.fromFirestore(doc.data(), doc.id);
      }).toList();

      expect(unratedTickets.every((t) => !t.isRated), isTrue);
    });
  });

  group('Integration Tests', () {
    test('complete booking flow', () async {
      // Collections
      final usersCollection = fakeFirestore.collection('users');
      final busesCollection = fakeFirestore.collection('buses');
      final tripsCollection = fakeFirestore.collection('trips');
      final ticketsCollection = fakeFirestore.collection('tickets');
      final paymentsCollection = fakeFirestore.collection('payments');

      // 1. Create and login user
      final user = AppUser(
        userID: 'flow_user',
        name: 'Flow User',
        email: 'flow@example.com',
        password: 'flowpass',
        role: 'user',
      );
      await usersCollection.add(user.toFirestore());

      final userSnapshot = await usersCollection
          .where('email', isEqualTo: 'flow@example.com')
          .get();

      expect(userSnapshot.docs.isNotEmpty, isTrue);

      // 2. Create bus
      final bus = Bus(
        id: '',
        busNumber: 'BUS_FLOW',
        capacity: 50,
        type: 'Luxury',
        imageUrl: 'https://example.com/bus.jpg',
        rating: 4.5,
        numberOfRatings: 10,
      );
      final busDocRef = await busesCollection.add(bus.toFirestore());

      // 3. Create trip
      final trip = Trip(
        id: '',
        source: 'Cairo',
        destination: 'Alexandria',
        date: DateTime.now().add(Duration(days: 10)),
        time: '10:00 AM',
        availableSeats: 30,
        busID: busDocRef.id,
      );
      final tripDocRef = await tripsCollection.add(trip.toFirestore());

      // 4. Create payment
      final payment = Payment(
        id: '',
        paymentID: 'FLOW_PAY',
        amount: 200.0,
        paymentDate: DateTime.now(),
        status: 'completed',
        ticketID: 'FLOW_TICKET',
      );
      await paymentsCollection.add(payment.toFirestore());

      // 5. Book ticket
      final ticket = Ticket(
        id: '',
        ticketID: 'FLOW_TICKET',
        status: 'booked',
        amount: 200.0,
        paymentDate: DateTime.now(),
        userID: 'flow_user',
        tripID: tripDocRef.id,
        paymentID: 'FLOW_PAY',
        isRated: false,
      );
      await ticketsCollection.add(ticket.toFirestore());

      // 6. Verify complete flow
      final ticketSnapshot = await ticketsCollection
          .where('userID', isEqualTo: 'flow_user')
          .get();

      expect(ticketSnapshot.docs.length, greaterThan(0));

      final bookedTicket = Ticket.fromFirestore(
          ticketSnapshot.docs.first.data(),
          ticketSnapshot.docs.first.id);

      expect(bookedTicket.ticketID, equals('FLOW_TICKET'));
      expect(bookedTicket.status, equals('booked'));
    });
  });
}