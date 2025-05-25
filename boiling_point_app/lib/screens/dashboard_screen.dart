import 'package:flutter/material.dart';
import 'feedback_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String role;
  final String location;

  DashboardScreen({required this.role, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Welcome, $role from $location', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              '⚠️ Heatwave Alert: Expected 44°C\n💧 Recommendation: Initiate water conservation',
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            ElevatedButton(
              child: Text('Give Feedback'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
