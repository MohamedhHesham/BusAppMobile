import 'package:busapp/screens/addbus_screen.dart';
import 'package:busapp/services/AuthService.dart';
import 'package:busapp/models/User.dart';
import 'package:busapp/models/Bus.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'search_screen.dart';
import 'addtrip_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const HomeScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int currentPage = 0;
  bool _isAdmin = false;
  final PageController _pageController = PageController(viewportFraction: 0.85);

  // ✅ Featured buses from database
  List<Bus> _featuredBuses = [];
  bool _isLoadingBuses = true;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.currentUser.role=='admin';
    _fetchFeaturedBuses(); // ✅ Fetch buses from Firestore
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null) {
        final next = page.round();
        if (currentPage != next) {
          setState(() {
            currentPage = next;
          });
        }
      }
    });
  }



  // ✅ Fetch buses from Firestore
  Future<void> _fetchFeaturedBuses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('buses')
          .limit(5)
          .get();

      setState(() {
        _featuredBuses = snapshot.docs
            .map((doc) => Bus.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _isLoadingBuses = false;
      });

      print('✅ Loaded ${_featuredBuses.length} featured buses');
    } catch (e) {
      print('❌ Error fetching featured buses: $e');
      setState(() {
        _isLoadingBuses = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomAppBar(
            height: 70,
            color: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketsScreen(currentUserId: widget.currentUser.userID),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.grey,
                      size: 26,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(currentUser: widget.currentUser),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.grey,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.currentUser.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.currentUser.email,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black87),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(currentUser: widget.currentUser),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.black87),
              title: const Text("Search For a Trip"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(currentUser: widget.currentUser),
                  ),
                );
              },
            ),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.bus_alert, color: Colors.black87),
                title: const Text("Add Bus"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBusScreen(
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              ),
            if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.add_box, color: Colors.black87),
              title: const Text("Add Trip"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTripScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFECEFF1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            // Featured Buses Title + Page count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Featured Buses",
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_featuredBuses.isNotEmpty)
                    Text(
                      "${currentPage + 1}/${_featuredBuses.length}",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoadingBuses
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black87,
                ),
              )
                  : _featuredBuses.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No buses available",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : PageView.builder(
                controller: _pageController,
                itemCount: _featuredBuses.length,
                itemBuilder: (context, index) {
                  final bus = _featuredBuses[index];
                  return AnimatedScale(
                    scale: currentPage == index ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ✅ Use bus.imageUrl from database
                            CachedNetworkImage(
                              imageUrl: bus.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Image not available",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.6, 1.0],
                                ),
                              ),
                            ),
                            // ✅ Bus info from database
                            Positioned(
                              bottom: 30,
                              left: 30,
                              right: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ Use bus.busNumber
                                  Text(
                                    bus.busNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // ✅ Use bus.rating with unrated check
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              bus.rating == -1 ? "Unrated" : bus.rating.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // ✅ Use bus.capacity
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.airline_seat_recline_normal,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${bus.capacity} Seats",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // ✅ Use bus.type
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      bus.type,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Page Indicators
            if (!_isLoadingBuses && _featuredBuses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _featuredBuses.length, // ✅ Use _featuredBuses.length
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage == index ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? Colors.black87
                            : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}