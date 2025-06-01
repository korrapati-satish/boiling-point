import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Stack to layer the background and the form
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Boiling Point themed background (gradient + bubbles)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF2c5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Bubbles for boiling effect
          Positioned.fill(
            child: CustomPaint(
              painter: _BoilingBubblesPainter(),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Card(
                color: Colors.white.withOpacity(0.90),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App logo or boiling point icon
                        Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Boiling Point Login',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.deepOrange[800],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => email = val!,
                          validator: (val) =>
                              val != null && val.contains('@') ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onSaved: (val) => password = val!,
                          validator: (val) =>
                              val != null && val.length >= 6 ? null : 'Min 6 characters',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              final form = _formKey.currentState!;
                              if (form.validate()) {
                                form.save();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logged in successfully')),
                                );
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                            child: const Text('Login'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text("Don't have an account? Sign Up"),
                        )
                      ],
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

// Custom painter for boiling bubbles background
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
