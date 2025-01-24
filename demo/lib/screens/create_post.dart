import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  final TextEditingController _generalLocationController =
      TextEditingController();

  final List<File> _images = []; // Changed to list of images
  String? _selectedCategory;

  final ApiService apiService = ApiService();
  bool _isLoading = false;

  final List<String> _categories = [
    'Adventure',
    'Hiking',
    'Skiing',
    'Road Trip',
    'Food Tour',
    'Others'
  ];

  // For Multi-Day Post
  late TabController _tabController;
  final TextEditingController _generalTitleController = TextEditingController();
  final List<Map<String, dynamic>> _multiDayTrips = [
    {
      'titleController': TextEditingController(),
      'contentController': TextEditingController(),
      'locationController': TextEditingController(),
      'images': <File>[],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

// Image section
  Future<void> _pickImage(Function(File) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        // _images.add(File(pickedFile.path));
        onImagePicked(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _addNewDayTrip() {
    setState(() {
      _multiDayTrips.add({
        'titleController': TextEditingController(),
        'contentController': TextEditingController(),
        'locationController': TextEditingController(),
        'images': <File>[],
      });
    });
  }

  Future<void> _submitPost() async {
  if (_tabController.index == 0) {
    // Single Day Post
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _locationController.text.isEmpty ||
        (_selectedCategory == null && _customCategoryController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final category = _customCategoryController.text.isNotEmpty
          ? _customCategoryController.text
          : _selectedCategory;

      await apiService.createPost(
        title: _titleController.text,
        location: _locationController.text,
        category: category,
        content: _contentController.text,
        imagePaths: _images.map((file) => file.path).toList(),
        period: 'oneday',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  } else {
    // Multi-Day Post
    if (_generalTitleController.text.isEmpty ||
        _generalLocationController.text.isEmpty ||
        _multiDayTrips.any((day) =>
            (day['titleController'] as TextEditingController).text.isEmpty ||
            (day['contentController'] as TextEditingController).text.isEmpty ||
            (day['locationController'] as TextEditingController).text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all required fields for all days')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final category = _customCategoryController.text.isNotEmpty
          ? _customCategoryController.text
          : _selectedCategory;

      await apiService.createPost(
        title: _generalTitleController.text,
        location: _generalLocationController.text,
        category: category,
        period: 'multipleday', // Determine type of post
        generalLocation: _generalLocationController.text,
        multiDayTrips: _multiDayTrips.map((day) {
          return {
            'title': (day['titleController'] as TextEditingController).text,
            'content': (day['contentController'] as TextEditingController).text,
            'location': (day['locationController'] as TextEditingController).text,
            'images': (day['images'] as List<File>)
                .map((file) => file.path)
                .toList(),
          };
        }).toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Multi-Day Post created successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating multi-day post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Single Day'),
            Tab(text: 'Multi Day'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 70,
              height: 35,
              child: TextButton(
                onPressed: _isLoading ? null : _submitPost,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Single Day Post UI
          _buildSingleDayPostUI(),
          // Multi-Day Post UI
          _buildMultiDayPostUI(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Category', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value;
            if (value != 'Others') {
              _customCategoryController.clear();
            }
          });
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Select a category',
        ),
      ),
      const SizedBox(height: 8),
      if (_selectedCategory == 'Others')
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a category',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customCategoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Custom category',
              ),
              onChanged: (value) {
                // Custom category can be handled here
              },
            ),
          ],
        ),
    ],
  );
}


  Widget _buildSingleDayPostUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePickerSection(_images, (file) {
              setState(() {
                _images.add(file);
              });
            }),
            _buildTextField('Title', _titleController),
            _buildTextField('Description', _contentController, maxLines: 5),
            _buildTextField('Location', _locationController),
            const SizedBox(height: 16),
            _buildCategorySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiDayPostUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Post Title', _generalTitleController),
            _buildTextField('General Location', _generalLocationController),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            ..._multiDayTrips.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              final images = day['images'] as List<File>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day ${index + 1}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildImagePickerSection(
                          images, (file) => images.add(file)),
                      _buildTextField('Day Title', day['titleController']),
                      _buildTextField('Description', day['contentController'],
                          maxLines: 5),
                      _buildTextField('Location', day['locationController']),
                      if (_multiDayTrips.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _multiDayTrips.removeAt(index)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addNewDayTrip,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              child: const Text('Add Day'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection(
      List<File> images, Function(File) onImagePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 13,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            images.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        GestureDetector(
          onTap: () => _pickImage(onImagePicked),
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Add Images', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _generalTitleController.dispose();
    _multiDayTrips.forEach((day) {
      (day['titleController'] as TextEditingController).dispose();
      (day['contentController'] as TextEditingController).dispose();
      (day['locationController'] as TextEditingController).dispose();
    });
    super.dispose();
  }
}
