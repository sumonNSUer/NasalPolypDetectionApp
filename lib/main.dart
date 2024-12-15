import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main Entry Point of the Application
void main() {
  runApp(NasalPolypDetectionApp());
}

// Section 1: Application Root
class NasalPolypDetectionApp extends StatelessWidget {
  const NasalPolypDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nasal Polyps Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NPD1(), // Start with the Welcome Page
    );
  }
}

// Section 2: NPD1 - Welcome Page
class NPD1 extends StatelessWidget {
  const NPD1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png', width: 150, height: 150),
            SizedBox(height: 20),
            Text(
              'Welcome To\nNasal Polyps Detection Mobile App',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NPD2()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CONTINUE'),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Warning: This App is just a Prototype Model'),
          ],
        ),
      ),
    );
  }
}

// Section 3: NPD2 - Upload/Take Picture Page
class NPD2 extends StatefulWidget {
  const NPD2({super.key});

  @override
  _NPD2State createState() => _NPD2State();
}

class _NPD2State extends State<NPD2> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  // Subsection: Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Subsection: Take Picture using Camera
  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Subsection: Upload Image and Process Detection
  Future<void> _uploadImage(File imageFile) async {
    final Uri uri = Uri.parse('http://10.0.2.2:5000/predict'); // For Android emulator
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        Map<String, dynamic> result;

        // Handle detection result
        if (decodedData is List && decodedData.isNotEmpty) {
          result = decodedData[0];
        } else if (decodedData is Map<String, dynamic>) {
          result = decodedData;
        } else {
          result = {'message': 'There is no nasal polyp detected in this image'};
        }

        setState(() {
          _result = result;
          _isLoading = false;
        });

        // Navigate to Result Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NPD3(image: _image!, result: _result!),
          ),
        );
      } else {
        _showError(response.statusCode);
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(dynamic error) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nasal Polyps Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
              ),
              child: _image == null
                  ? Center(child: Text('Upload Picture/Take Picture', textAlign: TextAlign.center))
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            _actionButtons(),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            Text('Warning: This App is just a Prototype Model'),
          ],
        ),
      ),
    );
  }

  // Helper: Buttons for Action
  Widget _actionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImageFromGallery,
              child: Row(
                children: [
                  Text('Upload Picture'),
                  Icon(Icons.upload),
                ],
              ),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _takePicture,
              child: Row(
                children: [
                  Text('Take Picture'),
                  Icon(Icons.camera_alt),
                ],
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            if (_image != null) {
              _uploadImage(_image!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload an image first')));
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SCAN NOW'),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back),
              Text('PREVIOUS'),
            ],
          ),
        ),
      ],
    );
  }
}

// Section 4: NPD3 - Detection Result Page
class NPD3 extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;

  const NPD3({super.key, required this.image, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nasal Polyps Detection Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Image.file(image, fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            Text(
              'Detection Result:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              result.containsKey('message')
                  ? result['message']
                  : 'Nasal Polyp Detected in this image',
              style: TextStyle(
                fontSize: 16,
                color: result.containsKey('message') ? Colors.red : Colors.green,
              ),
            ),
            if (!result.containsKey('message'))
              Text(
                'Confidence: ${result['confidence']}\n'
                    'Bounding Box: xmin: ${result['xmin']}, xmax: ${result['xmax']}, ymin: ${result['ymin']}, ymax: ${result['ymax']}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home),
                  Text('HOME'),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Warning: This App is just a Prototype Model'),
          ],
        ),
      ),
    );
  }
}
