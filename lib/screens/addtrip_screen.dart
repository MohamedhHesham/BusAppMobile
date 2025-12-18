import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/Trip.dart';
import 'package:busapp/services/TripService.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({Key? key}) : super(key: key);

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedBusNumber; // dropdown value
  String? _selectedBusId;     // Firestore doc ID
  int? _selectedBusCapacity;  // bus capacity
  String? _selectedTime;      // ✅ new dropdown value

  final TripService _tripService = TripService();
  List<Map<String, dynamic>> _buses = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    final snapshot = await FirebaseFirestore.instance.collection('buses').get();
    setState(() {
      _buses = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'busNumber': data['busNumber']?.toString() ?? '',
          'capacity': data['capacity'] ?? 0,
        };
      }).where((bus) => bus['busNumber']!.isNotEmpty).toList();
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

  Future<void> _addTrip() async {
    if (_sourceController.text.isEmpty ||
        _destinationController.text.isEmpty ||
        _selectedTime == null ||
        _selectedDate == null ||
        _selectedBusId == null ||
        _selectedBusCapacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final trip = Trip(
      id: '',
      source: _sourceController.text.toLowerCase().trim(),
      destination: _destinationController.text.toLowerCase().trim(),
      date: _selectedDate!,
      time: _selectedTime!, // ✅ use dropdown value
      availableSeats: _selectedBusCapacity!,
      busID: _selectedBusId!,
    );

    try {
      await _tripService.addTrip(trip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip added successfully")),
      );
      _sourceController.clear();
      _destinationController.clear();
      setState(() {
        _selectedDate = null;
        _selectedBusNumber = null;
        _selectedBusId = null;
        _selectedBusCapacity = null;
        _selectedTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add trip: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ generate 24 time options
    final timeOptions = List.generate(
      24,
          (hour) => "${hour.toString().padLeft(2, '0')}:00",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Add Trip")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _sourceController, decoration: const InputDecoration(labelText: "Source")),
            const SizedBox(height: 15),
            TextField(controller: _destinationController, decoration: const InputDecoration(labelText: "Destination")),
            const SizedBox(height: 15),
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
            const SizedBox(height: 15),

            // ✅ Time dropdown
            DropdownButtonFormField<String>(
              value: _selectedTime,
              items: timeOptions
                  .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedTime = val),
              decoration: const InputDecoration(labelText: "Select Time"),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _selectedBusNumber,
              items: _buses.map((bus) {
                return DropdownMenuItem<String>(
                  value: bus['busNumber'],
                  child: Text("${bus['busNumber']} (Capacity: ${bus['capacity']})"),
                );
              }).toList(),
              onChanged: (val) {
                final selectedBus = _buses.firstWhere((b) => b['busNumber'] == val);
                setState(() {
                  _selectedBusNumber = val;
                  _selectedBusId = selectedBus['id'];
                  _selectedBusCapacity = selectedBus['capacity'];
                });
              },
              decoration: const InputDecoration(labelText: "Select Bus Number"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addTrip, child: const Text("Add Trip")),
          ],
        ),
      ),
    );
  }
}
