import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstImageScreen extends StatefulWidget {
  const FirstImageScreen({super.key});

  @override
  _FirstImageScreenState createState() => _FirstImageScreenState();
}

class _FirstImageScreenState extends State<FirstImageScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  bool _imagesLoaded = false;

  final List<Map<String, String>> _onboardingPages = [
    {
      "image": "assets/icon/app_icon.png",
      "title": "Welcome to Survey Center",
      "description": "Your smart tool for academic surveys",
    },
    {
      "image": "assets/dive.jpg",
      "title": "Explore Available Surveys",
      "description": "Surveys waiting for your voice — answer now !",
    },
    {
      "image": "assets/history.jpg",
      "title": "Track Your Survey History",
      "description": "Track your participation and stay informed",
    },
    {
      "image": "assets/minipic.jpg",
      "title": "Ready to Dive In?",
      "description": "Every opinion counts !",
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingPreference();
    _preloadImages();
  }

  // Preload all images to ensure they're cached and ready
  Future<void> _preloadImages() async {
    try {
      for (var page in _onboardingPages) {
        // Precache each image with error handling
        await precacheImage(AssetImage(page["image"]!), context)
            .catchError((error) {
          print("Error preloading image ${page["image"]}: $error");
          // Continue with other images even if one fails
          return null;
        });
      }

      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    } catch (e) {
      print("Error in image preloading: $e");
      // Set images as loaded even if there was an error to prevent UI blocking
      if (mounted) {
        setState(() {
          _imagesLoaded = true;
        });
      }
    }
  }

  Future<void> _checkOnboardingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? dontShowAgain = prefs.getBool('dont_show_onboarding');
    if (dontShowAgain == true) {
      Navigator.pushReplacementNamed(context, '/complog');
    }
  }

  Future<void> _saveOnboardingPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dont_show_onboarding', value);
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/complog');
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area (image and text)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _onboardingPages[index];
                  return Column(
                    children: [
                      // Image container
                      Container(
                        width: screenSize.width,
                        height: screenSize.height * 0.6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: DecorationImage(
                            image: AssetImage(page["image"]!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Show a loading indicator if images aren't loaded yet
                        child: !_imagesLoaded && index != 0
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: const Color.fromARGB(255, 28, 51, 95),
                                ),
                              )
                            : null,
                      ),
                      // Text content below the image
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                page["title"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 28, 51, 95),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.01),
                              Text(
                                page["description"]!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.normal,
                                  color: const Color.fromARGB(255, 28, 51, 95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Fixed bottom section for indicators and controls
            Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Checkbox and button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Don't show again checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _dontShowAgain,
                            checkColor: Colors.white,
                            activeColor: Color.fromARGB(255, 28, 51, 95),
                            onChanged: (value) {
                              setState(() {
                                _dontShowAgain = value!;
                              });
                              _saveOnboardingPreference(value!);
                            },
                          ),
                          const Text("Don't show again"),
                        ],
                      ),
                      // Next/Skip button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _onboardingPages.length - 1) {
                            _navigateToLogin();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 28, 51, 95),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.08,
                            vertical: screenSize.height * 0.015,
                          ),
                          textStyle:
                              TextStyle(fontSize: screenSize.width * 0.04),
                        ),
                        child: Text(
                          _currentPage == _onboardingPages.length - 1
                              ? "Skip"
                              : "Next",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
