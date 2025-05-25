import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class InputScreen extends StatelessWidget {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Role & Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: roleController, decoration: InputDecoration(labelText: 'Role')),
            TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location')),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Continue'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(
                      role: roleController.text,
                      location: locationController.text,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
