import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Changed from login_screen.dart

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Auto-slide: ~300ms per slide so all 3 happen roughly within 1 second
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (_currentPage < 2) {
        _currentPage++;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      } else {
        _timer?.cancel();
      }
    });

    // keep state in sync if user swipes manually
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null) {
        final round = page.round();
        if (round != _currentPage) {
          setState(() => _currentPage = round);
        }
      }
    });

    // Optional: Precache images if possible, otherwise they load lazily
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCenteredMedia({required Widget child}) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.35,
        child: Center(child: child),
      ),
    );
  }

  Widget _buildDot(int index) {
    final bool active = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      width: active ? 22 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFAB0202).withValues(alpha: active ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // PageView expands to fill available vertical space
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(), // Better physics
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCenteredMedia(
                        child: Image.asset(
                          'assets/images/intro1.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Donate Blood, Save Lives",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAB0202),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          "Your small effort can give someone another chance at life.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  // 2) Image slide
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCenteredMedia(
                        child: Image.asset(
                          'assets/images/intro2.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.location_on,
                              size: 100,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Find Donors Nearby",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAB0202),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          "Locate and connect with donors in your area quickly.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),

                  // 3) Image slide with Get Started button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCenteredMedia(
                        child: Image.asset(
                          'assets/images/intro3.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.people,
                              size: 100,
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Join the Life-Saving Network",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAB0202),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          "Become part of a caring community that makes a difference.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAB0202),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const LoginPage(), // Updated class name
                            ),
                          );
                        },
                        child: const Text(
                          "Get Started",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dots (placed a bit higher than bottom)
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, _buildDot),
            ),
            const SizedBox(height: 18), // extra space at bottom
          ],
        ),
      ),
    );
  }
}
