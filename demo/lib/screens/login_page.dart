import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  double cardOffset = 0.0;
  final double threshold = 100.0;
  late String _currentWallpaper;
  bool isFormVisible = false; // Control the appearance of the card
  bool enableInteraction = false; // Control form interaction
  double _wallpaperOpacity = 1.0; // Control the gradient
  double _wallpaperScale = 1.0; // Control the scale

  final List<String> wallpapers = [
    'assets/wallpapers/sample1.jpg',
    'assets/wallpapers/sample2.jpg',
    'assets/wallpapers/sample3.jpg',
    'assets/wallpapers/sample4.jpg',
    'assets/wallpapers/sample5.jpg',
    'assets/wallpapers/sample6.jpg',
    'assets/wallpapers/sample7.jpg',
    'assets/wallpapers/sample8.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentWallpaper = randomWallpaper;
  }

  String get randomWallpaper {
    final random = Random();
    return wallpapers[random.nextInt(wallpapers.length)];
  }

  void changeWallpaper() {
    setState(() {
      isFormVisible = false; // Make the card return to the bottom
      enableInteraction = false; // Disable input interaction
      cardOffset = 0.0; // Reset the sliding state
      _wallpaperOpacity = 0.0; // Set the opacity to 0, triggering the gradient
      _wallpaperScale = 1.1; // Slightly enlarge
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _currentWallpaper = randomWallpaper; // Update wallpaper
      });
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        _wallpaperOpacity = 1.0; // Gradient back to normal
        _wallpaperScale = 1.0; // Scale back to normal
      });
    });
  }

  void showLoginForm() {
    setState(() {
      isFormVisible = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        enableInteraction = true;
      });
    });
  }

  void login({bool triggeredBySwipe = false}) async {
    if (!enableInteraction) return;

    final String username = _emailController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showErrorSnackbar('Please fill out all fields');
      isFormVisible = true; // Ensure the form is visible
      return;
    }

    setState(() {
      isLoading = true;
      if (triggeredBySwipe) {
        isFormVisible = false; // Hide the card when swiping down
      }
    });

    try {
      final bool success = await ApiService().login(username, password);
      if (success) {
        Navigator.pushReplacementNamed(context, '/feed');
      } else {
        showErrorSnackbar('Invalid username or password');
        if (triggeredBySwipe) {
          setState(() {
            isFormVisible = true; // Restore the card when login fails
          });
        }
      }
    } catch (e) {
      showErrorSnackbar('An error occurred: $e');
      if (triggeredBySwipe) {
        setState(() {
          isFormVisible = true; // Restore the card when login fails
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // Make the outer layer transparent
        elevation: 0, // Remove the shadow
        margin: const EdgeInsets.only(bottom: 10), // Adjust the bottom spacing
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center, // Center the text
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void animateCardToHide() {
    FocusScope.of(context).unfocus(); // Collapse the keyboard

    setState(() {
      cardOffset = 500; // Slide the card out of the screen
      isFormVisible = false; // Hide the form
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        cardOffset = 0; // Reset the offset, ready for the next login
      });
    });

    login(triggeredBySwipe: true);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600), // Longer time for smoother animation
              tween:
                  Tween<double>(begin: _wallpaperScale, end: _wallpaperScale),
              curve: Curves.easeInOut,
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _wallpaperOpacity,
                    child: Image.asset(
                      _currentWallpaper,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // Change wallpaper button
          Positioned(
            top: 40,
            right: 20,
            child: Opacity(
              opacity: 0.6,
              child: IconButton(
                icon: const Icon(Icons.image, size: 28, color: Colors.white),
                onPressed: changeWallpaper,
                tooltip: "Change Wallpaper",
              ),
            ),
          ),

          // Bottom Login button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 150),
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => isFormVisible ? login() : showLoginForm(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor:
                      isFormVisible ? primaryColor : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isFormVisible ? primaryColor : Colors.white,
                      width: 3,
                    ),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        "Log In",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),

          // Login card (animated from the bottom)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            bottom: isFormVisible ? 260 : -screenHeight * 0.8,
            left: 35,
            right: 35,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (!enableInteraction) return;
                setState(() {
                  cardOffset += details.primaryDelta!;
                });
              },
              onVerticalDragEnd: (details) {
                if (!enableInteraction) return;
                if (cardOffset > threshold) {
                  animateCardToHide(); // Hide the card directly
                } else {
                  setState(() {
                    cardOffset = 0; // Otherwise, return to the original position
                  });
                }
              },
              child: Transform.translate(
                offset: Offset(0, cardOffset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/tm_logo.png',
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Username",
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17), // Set the corner radius
                                borderSide: const BorderSide(
                                    color: greyColor), // Default gray border
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: const BorderSide(
                                    color: greyColor), // Unselected state
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2), // Change to primaryColor when selected
                              ),
                            ),
                            enabled: enableInteraction,
                          ),

const SizedBox(height: 20),

                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    const BorderSide(color: greyColor),
                              ),
                              enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    const BorderSide(color: greyColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                            enabled: enableInteraction,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              "Don't have an account? Register here",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
