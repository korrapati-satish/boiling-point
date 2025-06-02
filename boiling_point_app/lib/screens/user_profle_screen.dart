import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String role;
  final String detail; // NGO or Ward detail
  final int greenPoints;

  const UserProfileScreen({
    Key? key,
    required this.userName,
    required this.role,
    required this.detail,
    required this.greenPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0f2027);
    const Color secondaryColor = Color(0xFF2c5364);
    const Color accentColor = Colors.deepOrange;
    const Color cardColor = Colors.white;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Bubbles
          Positioned.fill(
            child: CustomPaint(
              painter: _BoilingBubblesPainter(),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    color: cardColor.withOpacity(0.92),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: primaryColor,
                              child: const Icon(Icons.person, size: 60, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Divider(
                            color: accentColor.withOpacity(0.2),
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'Green Points: $greenPoints',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Implement logout logic
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.logout, color: Colors.deepOrange),
                              label: const Text(
                                'Back to Home',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  fontSize: 18,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.deepOrange.withOpacity(0.10),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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

// Reuse the bubbles painter from your login screen
class _BoilingBubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.10);
    final bubbles = [
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.9),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.75),
    ];
    final radii = [32.0, 24.0, 18.0, 14.0, 20.0];

    for (int i = 0; i < bubbles.length; i++) {
      canvas.drawCircle(bubbles[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}