import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  final ApiService apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Convert to File
      });
    }
  }

  void _submitPost() async {
    // Print a message when the post button is clicked
    print('Post button clicked!');

    // Handle post submission logic here
    print('Title: ${_titleController.text}');
    print('Content: ${_contentController.text}');
    print('Image Path: ${_image?.path}');

    // Call the createPost method to send data to the backend
    await apiService.createPost(
      _titleController.text,
      _contentController.text,
      _image?.path, // Pass the image path if needed
    );

    // Optionally, you can show a success message or navigate to another page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Container(
            width: 70,
            height: 35,
            child: TextButton(
              onPressed: _submitPost,
              child: Text('Post', style: TextStyle(color: Colors.white)),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.orange),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _image == null
                    ? const Center(child: Text('Add Image', style: TextStyle(color: Colors.grey)))
                    : Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Add a title',
                labelStyle: TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(76, 118, 118, 118))),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Add text',
                labelStyle: TextStyle(color: Colors.grey),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () {
                // Handle location selection
              },
              child: const Text('Select location', style: TextStyle(color: Color.fromARGB(255, 157, 205, 245))),
            ),
          ],
        ),
      ),
    );
  }
}
