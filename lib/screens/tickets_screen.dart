import 'package:flutter/material.dart';
import 'package:busapp/models/Ticket.dart';
import 'package:busapp/models/Trip.dart';
import 'package:busapp/models/Bus.dart';
import 'package:busapp/services/TicketService.dart';
import 'package:busapp/services/TripService.dart';
import 'package:busapp/services/BusService.dart';

class TicketsScreen extends StatefulWidget {
  final String currentUserId;

  const TicketsScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  final TripService _tripService = TripService();
  final BusService _busService = BusService();

  List<Ticket> _tickets = [];
  Map<String, Trip> _tripMap = {};
  Map<String, Bus> _busMap = {};
  bool _loading = true;
  Set<String> _cancellingTickets = {};

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _ticketService.getTicketsByUser(widget.currentUserId);
      final trips = await _tripService.getTrips();
      final buses = await _busService.getBuses();

      // Sort tickets by trip date (newest first)
      tickets.sort((a, b) {
        final tripA = trips.firstWhere((t) => t.id == a.tripID, orElse: () => trips.first);
        final tripB = trips.firstWhere((t) => t.id == b.tripID, orElse: () => trips.first);
        return tripB.date.compareTo(tripA.date);
      });

      setState(() {
        _tickets = tickets;
        _tripMap = {for (var trip in trips) trip.id: trip};
        _busMap = {for (var bus in buses) bus.id: bus};
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load tickets: $e")),
      );
    }
  }

  bool _isTripToday(Trip trip) {
    final now = DateTime.now();
    final tripDate = trip.date;
    return tripDate.year == now.year &&
        tripDate.month == now.month &&
        tripDate.day == now.day;
  }

  bool _isTripPast(Trip trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDate = DateTime(trip.date.year, trip.date.month, trip.date.day);
    return tripDate.isBefore(today);
  }

  Future<void> _showRatingDialog(Ticket ticket, Trip trip, Bus bus) async {
    int selectedRating = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Rate Your Trip',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience on bus ${bus.busNumber}?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    iconSize: 20,
                    icon: Icon(
                      starValue <= selectedRating ? Icons.star : Icons.star_border,
                      color: starValue <= selectedRating ? Colors.amber : Colors.grey[400],
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = starValue;
                      });
                    },
                  );
                }),
              ),
              if (selectedRating > 0) ...[
                const SizedBox(height: 10),
                Text(
                  _getRatingText(selectedRating),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () {
                Navigator.pop(context);
                _submitRating(ticket, bus.id, selectedRating.toDouble());
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitRating(Ticket ticket, String busId, double rating) async {
    try {
      // Add rating to bus
      await _busService.addRating(busId, rating);

      // Mark ticket as rated
      await _ticketService.markTicketAsRated(ticket.id);

      // Refresh tickets to update UI
      await _fetchTickets();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCancellationDialog(Ticket ticket) async {
    final trip = _tripMap[ticket.tripID];

    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip information not found")),
      );
      return;
    }

    if (ticket.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This ticket is already cancelled")),
      );
      return;
    }

    final canCancel = await _ticketService.canCancelTicket(ticket.tripID);
    if (!canCancel) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Cannot Cancel"),
          content: const Text(
            "This ticket cannot be cancelled because the trip has already started or is too close.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Ticket"),
        content: Text(
          "Are you sure you want to cancel your trip from ${trip.source} → ${trip.destination} "
              "on ${trip.date.toLocal().toString().split(' ')[0]} at ${trip.time}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Ticket"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelTicket(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Cancel Ticket"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTicket(Ticket ticket) async {
    setState(() {
      _cancellingTickets.add(ticket.id);
    });

    final result = await _ticketService.cancelTicket(
      userId: widget.currentUserId,
      tripId: ticket.tripID,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      await _fetchTickets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _cancellingTickets.remove(ticket.id);
    });
  }

  Widget _buildStatusBadge(Trip? trip, bool isCancelled) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Cancelled",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red[900],
          ),
        ),
      );
    }

    if (trip == null) return const SizedBox.shrink();

    final isPastTrip = _isTripPast(trip);
    final isTodayTrip = _isTripToday(trip);

    if (isPastTrip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Completed",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }

    if (isTodayTrip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.today, size: 14, color: Colors.green[900]),
            const SizedBox(width: 4),
            Text(
              "Today",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Upcoming",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No tickets yet",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchTickets,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _tickets.length,
          itemBuilder: (context, index) {
            final ticket = _tickets[index];
            final trip = _tripMap[ticket.tripID];
            final bus = _busMap[trip?.busID ?? ''];
            final isCancelling = _cancellingTickets.contains(ticket.id);
            final isCancelled = ticket.status == 'cancelled';
            final isPastTrip = trip != null && _isTripPast(trip);
            final isRated = ticket.isRated; // Use isRated from ticket model

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: bus != null
                              ? Image.network(
                            bus.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.directions_bus, size: 40),
                                ),
                          )
                              : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.directions_bus, size: 40),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip != null
                                    ? "${trip.source} → ${trip.destination}"
                                    : "Trip ID: ${ticket.tripID}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration:
                                  isCancelled ? TextDecoration.lineThrough : null,
                                  color: isCancelled ? Colors.grey : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (trip != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.date.toLocal().toString().split(' ')[0],
                                      style: TextStyle(
                                          color: Colors.grey[700], fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.time,
                                      style: TextStyle(
                                          color: Colors.grey[700], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                              if (bus != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Bus: ${bus.busNumber}",
                                  style:
                                  TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _buildStatusBadge(trip, isCancelled),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Booked: ${ticket.paymentDate.toLocal().toString().split(' ')[0]}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        // Show cancel button for upcoming trips
                        if (!isPastTrip &&
                            !isCancelled &&
                            trip != null &&
                            !_isTripToday(trip))
                          isCancelling
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : TextButton.icon(
                            onPressed: () => _showCancellationDialog(ticket),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text("Cancel"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        // Show rate button for completed trips that haven't been rated
                        if (isPastTrip && !isCancelled && bus != null && !isRated)
                          TextButton.icon(
                            onPressed: () => _showRatingDialog(ticket, trip!, bus),
                            icon: const Icon(Icons.star_border, size: 18),
                            label: const Text("Rate"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.amber[700],
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        // Show rated indicator for completed trips that have been rated
                        if (isPastTrip && !isCancelled && isRated)
                          Row(
                            children: [
                              Icon(Icons.star, size: 18, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text(
                                "Rated",
                                style: TextStyle(
                                  color: Colors.amber[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}