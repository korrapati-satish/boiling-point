import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  final TextEditingController feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Action & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(labelText: 'Describe what action you took'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: () {
                // Call backend or storage service
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Feedback submitted')),
                );
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
}
