import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/services/BusService.dart';
import 'package:busapp/services/AuthService.dart';
import 'package:busapp/models/Bus.dart';
import 'package:busapp/models/User.dart';

class AddBusScreen extends StatefulWidget {
  final AppUser currentUser;

  const AddBusScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final BusService _busService = BusService();
  final AuthService _authService = AuthService();

  String _selectedType = 'Standard';
  double _rating = -1.0;
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  final List<String> _busTypes = ['Standard', 'Luxury', 'Express', 'Sleeper'];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin(widget.currentUser.userID);
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isCheckingAdmin = false;
    });
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Admin privileges required'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleAddBus() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final busNumber = _busNumberController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim());
      final imageUrl = _imageUrlController.text.trim();

      if (capacity == null || capacity <= 0) {
        throw Exception('Invalid capacity');
      }

      final existing = await FirebaseFirestore.instance
          .collection('buses')
          .where('busNumber', isEqualTo: busNumber)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus number "$busNumber" already exists!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final newBus = Bus(
        id: '',
        busNumber: busNumber,
        capacity: capacity,
        type: _selectedType,
        imageUrl: imageUrl,
        rating: _rating,
        numberOfRatings: 0,
      );

      await _busService.addBus(newBus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _busNumberController.clear();
      _capacityController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedType = 'Standard';
        _rating = -1.0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied: Admin privileges required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Bus')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _busNumberController,
                  decoration: const InputDecoration(labelText: 'Bus Number'),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter bus number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter capacity';
                    final cap = int.tryParse(value.trim());
                    if (cap == null || cap <= 0) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: _busTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val ?? 'Standard'),
                  decoration: const InputDecoration(labelText: 'Bus Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter image URL' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddBus,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Bus'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
