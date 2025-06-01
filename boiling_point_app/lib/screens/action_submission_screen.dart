import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ActionSubmissionScreen extends StatefulWidget {
  final String actionName;
  final String userId;

  const ActionSubmissionScreen({
    Key? key,
    required this.actionName,
    required this.userId,
  }) : super(key: key);

  @override
  _ActionSubmissionScreenState createState() => _ActionSubmissionScreenState();
}

class _ActionSubmissionScreenState extends State<ActionSubmissionScreen> {
  File? _selectedFile;
  String? _fileType; // 'image' or 'pdf'
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileType = 'image';
        _uploadStatus = null;
      });
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'pdf';
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
      var uri = Uri.parse('https://your-backend-url.com/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['actionName'] = widget.actionName;
      request.fields['userId'] = widget.userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path,
          filename: basename(_selectedFile!.path),
        ),
      );

      var response = await request.send();

      setState(() {
        _isUploading = false;
        if (response.statusCode == 200) {
          _uploadStatus = 'Upload successful!';
        } else {
          _uploadStatus = 'Upload failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: $e';
      });
    }
  }

  Widget _previewFile() {
    if (_selectedFile == null) {
      return Text('No file selected.',
          style: TextStyle(color: Colors.white70, fontSize: 16));
    }
    if (_fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedFile!, height: 200),
      );
    } else if (_fileType == 'pdf') {
      return ListTile(
        leading: Icon(Icons.picture_as_pdf, size: 48, color: Colors.orangeAccent),
        title: Text(
          basename(_selectedFile!.path),
          style: TextStyle(color: Colors.white),
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
                    Text(
                      'Action: ${widget.actionName}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                        ElevatedButton.icon(
                          icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                          label: Text('Pick PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: _isUploading ? null : _pickPdf,
                        ),
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
                        onPressed: (_selectedFile != null && !_isUploading)
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