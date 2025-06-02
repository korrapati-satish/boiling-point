import 'dart:convert';
import 'dart:io';
import 'package:boiling_point_app/models/boiling_point.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

class ActionSubmissionScreen extends StatefulWidget {
  final String action;
  final String emailId;
  final String location;
  final String role;
  final List<BoilingPointActionStep> steps;

  const ActionSubmissionScreen({
    Key? key,
    required this.action,
    required this.emailId,
    required this.location,
    required this.role,
    required this.steps,
  }) : super(key: key);

  @override
  _ActionSubmissionScreenState createState() => _ActionSubmissionScreenState();
}

class _ActionSubmissionScreenState extends State<ActionSubmissionScreen> {
  List<File> _selectedFiles = [];
  File? _selectedFile;
  String? _fileType; // 'image' or 'pdf'
  bool _isUploading = false;
  String? _uploadStatus;
  String? _message;
  String? _rating;
  String? _reason;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        // Add all selected images to the list
        _selectedFiles = pickedFiles.map((xfile) => File(xfile.path)).toList();
        // For preview and upload, pick the first image (can be changed for multi-upload)
        _selectedFile = File(pickedFiles.first.path);
        _fileType = 'image';
        _uploadStatus = null;
      });
    }
  }

  Future<void> _submitEvidence() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = null;
    });

    try {
      var uri = Uri.parse('http://10.0.2.2:8000/submit-steps');
      //var uri = Uri.parse('https://boiling-point-server-566823910614.us-south1.run.app/submit-steps');      

      var request = http.MultipartRequest('POST', uri);

      // Add the completion field (as in your curl)
      //request.fields['completion'] = '[{"email_id":"john@gmail.com","role":"Farmer","location":"Bangalore","action":"Implement sustainable farming practices such as crop rotation, intercropping, and organic farming to maintain soil health, reduce water consumption, and minimize chemical use. This approach can improve productivity, resilience, and long-term sustainability.","step_description":"Educate farmers about sustainable farming practices such as crop rotation, intercropping, and organic farming. This can be done through workshops, training sessions, and demonstrations."},{"email_id":"john@gmail.com","role":"Farmer","location":"Bangalore","action":"Implement sustainable farming practices such as crop rotation, intercropping, and organic farming to maintain soil health, reduce water consumption, and minimize chemical use. This approach can improve productivity, resilience, and long-term sustainability.","step_description":"Promote the use of locally adapted crop varieties that are resilient to local climate conditions and require less water. Distribute seeds and provide information on their cultivation."},{"email_id":"john@gmail.com","role":"Farmere","location":"Bangalore","action":"Implement sustainable farming practices such as crop rotation, intercropping, and organic farming to maintain soil health, reduce water consumption, and minimize chemical use. This approach can improve productivity, resilience, and long-term sustainability.","step_description":"Establish a network of local extension services to provide ongoing support and guidance to farmers. This can include regular visits to farms, monitoring of farming practices, and timely advice."},{"email_id":"john@gmail.com","role":"Farmer","location":"Bangalore","action":"Implement sustainable farming practices such as crop rotation, intercropping, and organic farming to maintain soil health, reduce water consumption, and minimize chemical use. This approach can improve productivity, resilience, and long-term sustainability.","step_description":"Encourage the adoption of organic farming by providing resources and support for farmers to transition from conventional to organic practices. This can include assistance with certification processes and access to organic inputs."},{"email_id":"john@gmail.com","role":"Farmer","location":"Bangalore","action":"Implement sustainable farming practices such as crop rotation, intercropping, and organic farming to maintain soil health, reduce water consumption, and minimize chemical use. This approach can improve productivity, resilience, and long-term sustainability.","step_description":"Monitor and evaluate the impact of these practices on soil health, water consumption, and productivity. Use this information to refine and improve farming practices over time."}]';

      request.fields['completion'] = jsonEncode(widget.steps.map((step) => {
        'email_id': widget.emailId,
        'role': widget.role,
        'location': widget.location,
        'action': widget.action,
        'step_description': step.description,
      }).toList());

      print('Completion field: ${request.fields['completion']}');

      // Add all selected images as 'step_photos'
      for (var file in _selectedFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
        'step_photos',
        file.path,
        filename: basename(file.path),
        contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Debug log: print request details
      print('--- HTTP REQUEST ---');
      print('URL: ${request.url}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => f.filename).toList()}');

      var response = await request.send();

      // Debug log: print response details
      print('--- HTTP RESPONSE ---');
      print('Status code: ${response.statusCode}');
      final respStr = await response.stream.bytesToString();
      print('Response body: $respStr');

      // Parse JSON and extract message, rating, and reason

      setState(() {
      _isUploading = false;
      if (response.statusCode == 200) {
        _uploadStatus = 'Upload successful!';

        try {
          final Map<String, dynamic> respJson = respStr.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(respStr)) : {};
          _message = respJson['message'];
          _rating = respJson['ratings']?['rating'];
          _reason = respJson['ratings']?['reason'];
          print('Message: $_message');
          print('Rating: $_rating');
          print('Reason: $_reason');
        } catch (e) {
          print('Failed to parse response JSON: $e');
        }

      } else {
        _uploadStatus = 'Upload failed. Please try again.';
      }
      });
    } catch (e) {
      print('--- HTTP ERROR ---');
      print(e);
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: $e';
      });
    }
  }

  Widget _previewFile() {
    if (_selectedFiles.isEmpty) {
      return Text('No file selected.',
          style: TextStyle(color: Colors.white70, fontSize: 16));
    }
    if (_fileType == 'image') {
      return SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedFiles.length,
          separatorBuilder: (_, __) => SizedBox(width: 12),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedFiles[index],
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Submit Evidence',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF512F), // Orange Red
              Color(0xFFDD2476), // Pinkish
              Color(0xFFFFA751), // Yellow Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.black.withOpacity(0.7),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Boiling Point',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      color: Colors.deepOrange.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          'Action:',
                          style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.action,
                          style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'User: ${widget.emailId}',
                          style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Role: ${widget.role}',
                          style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Location: ${widget.location}',
                          style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Number of Steps: ${widget.steps.length}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ],
                      ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _previewFile(),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.photo, color: Colors.white),
                          label: Text('Pick Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: _isUploading ? null : _pickImage,
                        ),
                        SizedBox(width: 16),                        
                      ],
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isUploading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Submit Evidence',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                        onPressed: (_selectedFiles != null && !_isUploading)
                            ? _submitEvidence
                            : null,
                      ),
                    ),
                    if (_uploadStatus != null) ...[
                      SizedBox(height: 20),
                      Center(
                      child: Text(
                        _uploadStatus!,
                        style: TextStyle(
                        color: _uploadStatus == 'Upload successful!'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        ),
                      ),
                      ),
                      if (_message != null) ...[
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                        _message!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                        ),
                      ),
                      ],
                      if (_rating != null) ...[
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                        'Rating: $_rating',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        ),
                      ),
                      ],
                      if (_reason != null) ...[
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                        'Reason: $_reason',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        ),
                      ),
                      ],
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}