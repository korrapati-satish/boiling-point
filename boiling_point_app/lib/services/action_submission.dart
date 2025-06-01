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
      return Text('No file selected.');
    }
    if (_fileType == 'image') {
      return Image.file(_selectedFile!, height: 200);
    } else if (_fileType == 'pdf') {
      return ListTile(
        leading: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
        title: Text(basename(_selectedFile!.path)),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Evidence')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action: ${widget.actionName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _previewFile(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text('Pick Image'),
                  onPressed: _isUploading ? null : _pickImage,
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text('Pick PDF'),
                  onPressed: _isUploading ? null : _pickPdf,
                ),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Submit Evidence'),
              onPressed: (_selectedFile != null && !_isUploading)
                  ? _submitEvidence
                  : null,
            ),
            if (_uploadStatus != null) ...[
              SizedBox(height: 20),
              Text(
                _uploadStatus!,
                style: TextStyle(
                  color: _uploadStatus == 'Upload successful!'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}