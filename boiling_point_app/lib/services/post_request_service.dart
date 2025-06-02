import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostRequestWithButton extends StatefulWidget {
  const PostRequestWithButton({super.key});

  @override
  State<PostRequestWithButton> createState() => _PostRequestWithButtonState();
}

class _PostRequestWithButtonState extends State<PostRequestWithButton> {
  String responseText = 'Click the button to send POST request';

  Future<void> sendPostRequest() async {
    // const url = 'http://127.0.0.1:8000/get-options';
    final url = 'https://boiling-point-server-566823910614.us-south1.run.app/get-actions';

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "title": "Flutter Post",
      "body": "This is a post from a Flutter app",
      "userId": 1
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 201) {
        setState(() {
          responseText = 'Success:\n${response.body}';
        });
      } else {
        setState(() {
          responseText = 'Failed with status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        responseText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POST Request Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: sendPostRequest,
              child: const Text('Send POST Request'),
            ),
            const SizedBox(height: 20),
            Text(
              responseText,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
