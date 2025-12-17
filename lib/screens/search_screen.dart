import 'package:busapp/models/User.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:busapp/models/Trip.dart';
import 'package:busapp/models/Bus.dart';
import 'package:busapp/services/TripService.dart';
import 'package:busapp/services/BusService.dart';
import 'payment_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppUser currentUser;

  const SearchScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TripService _tripService = TripService();
  final BusService _busService = BusService();

  String? _selectedSource;
  String? _selectedDestination;
  DateTime? _selectedDate;
  int? _selectedHour; // null = "All", 0–23 = specific hour

  List<String> _sources = [];
  List<String> _destinations = [];
  List<Trip> _results = [];
  List<Trip> _allResults = [];
  Map<String, Bus> _busMap = {};

  @override
  void initState() {
    super.initState();
    _fetchSourcesAndDestinations();
    _fetchBuses();
  }

  Future<void> _fetchSourcesAndDestinations() async {
    final trips = await _tripService.getTrips();
    setState(() {
      _sources = trips.map((t) => t.source).toSet().toList();
      _destinations = trips.map((t) => t.destination).toSet().toList();
    });
  }

  Future<void> _fetchBuses() async {
    final buses = await _busService.getBuses();
    setState(() {
      _busMap = {for (var bus in buses) bus.id: bus};
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _performSearch() async {
    if (_selectedSource == null || _selectedDestination == null) return;
    final trips = await _tripService.searchTrips(_selectedSource!, _selectedDestination!);

    setState(() {
      _allResults = trips.where((t) {
        if (t.availableSeats <= 0) return false;

        // ✅ Build full trip DateTime (date + time string)
        final tripDateTime = DateTime(
          t.date.year,
          t.date.month,
          t.date.day,
          int.tryParse(t.time.split(':')[0]) ?? 0,
          int.tryParse(t.time.split(':').length > 1 ? t.time.split(':')[1] : '0') ?? 0,
        );

        // ✅ Exclude trips already started
        if (tripDateTime.isBefore(DateTime.now())) return false;

        // filter by selected date (compare YYYY-MM-DD)
        if (_selectedDate != null) {
          final tripDate = t.date.toLocal().toString().split(' ')[0];
          final selectedDateStr = _selectedDate!.toLocal().toString().split(' ')[0];
          if (tripDate != selectedDateStr) return false;
        }

        return true;
      }).toList();

      // ✅ Sort by date first, then by time
      _allResults.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;

        final aHour = int.tryParse(a.time.split(':')[0]) ?? 0;
        final aMin = int.tryParse(a.time.split(':').length > 1 ? a.time.split(':')[1] : '0') ?? 0;
        final bHour = int.tryParse(b.time.split(':')[0]) ?? 0;
        final bMin = int.tryParse(b.time.split(':').length > 1 ? b.time.split(':')[1] : '0') ?? 0;

        final aMinutes = aHour * 60 + aMin;
        final bMinutes = bHour * 60 + bMin;

        return aMinutes.compareTo(bMinutes);
      });

      _applyHourFilter();
    });
  }


  void _applyHourFilter() {
    if (_selectedHour == null) {
      _results = _allResults;
    } else {
      _results = _allResults.where((trip) {
        final hour = int.tryParse(trip.time.split(':')[0]) ?? -1;
        return hour == _selectedHour;
      }).toList();
    }
    setState(() {});
  }

  Future<void> _bookTrip(BuildContext context, Trip trip) async {
    if (trip.availableSeats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No seats available for this trip")),
      );
      return;
    }

    // Navigate to payment screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          trip: trip,
          bus: _busMap[trip.busID],
          currentUserId: widget.currentUser.userID,
        ),
      ),
    );

    // Refresh results when coming back
    _performSearch();
  }

  String _formatTime24(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]).toString().padLeft(2, '0');
      final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return "$hour:$minute";
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ✅ Combined header with gradient and time filter
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          "Search Trips",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time filter (inside the gradient)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 6),
                          child: Text(
                            'Filter by Time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 45,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 25, // "All Times" + 24 hours
                            itemBuilder: (context, index) {
                              final isAll = index == 0;
                              final hour = isAll ? null : index - 1;
                              final isSelected = _selectedHour == hour;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedHour = hour;
                                      _applyHourFilter();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.25)
                                          : Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        isAll ? "All Times" : "${hour!.toString().padLeft(2, '0')}:00",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search form: source, destination, date, search button
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSource,
                        isExpanded: true,
                        items: _sources.map((src) => DropdownMenuItem(value: src, child: Text(src))).toList(),
                        onChanged: (val) => setState(() => _selectedSource = val),
                        decoration: const InputDecoration(labelText: "Source"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDestination,
                        isExpanded: true,
                        items: _destinations.map((dest) => DropdownMenuItem(value: dest, child: Text(dest))).toList(),
                        onChanged: (val) => setState(() => _selectedDestination = val),
                        decoration: const InputDecoration(labelText: "Destination"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? "No date chosen"
                            : "Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                      ),
                    ),
                    TextButton(onPressed: _pickDate, child: const Text("Pick Date")),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text("No trips found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final trip = _results[index];
                final bus = _busMap[trip.busID];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bus != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: bus.imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.directions_bus, size: 60),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trip_origin, color: Colors.blueGrey[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${trip.source} → ${trip.destination}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.directions_bus, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  bus != null ? "Bus: ${bus.busNumber}" : "Bus ID: ${trip.busID}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  trip.date.toLocal().toString().split(' ')[0],
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime24(trip.time),
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.event_seat, color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${trip.availableSeats} seats available",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: trip.availableSeats < 5 ? Colors.orange[700] : Colors.grey[700],
                                    fontWeight: trip.availableSeats < 5 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if(widget.currentUser.role=="user")
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: trip.availableSeats > 0
                                    ? () => _bookTrip(context, trip)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey[800],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  "Book Now",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}