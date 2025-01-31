import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage>
    with SingleTickerProviderStateMixin {
  //Single Day data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  //Multi Day data
  final TextEditingController _generalTitleController = TextEditingController();
  final TextEditingController _generalLocationController =
      TextEditingController();
  final List<Map<String, dynamic>> _multiDayTrips = [];

  final TextEditingController _customCategoryController =
      TextEditingController();
  String? _selectedCategory;
  final List<File> _images = [];

  //Location data
  String? _locationName;
  LatLng? _selectedLocation;

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _addNewDayTrip(); // Add the first day by default
  }

  void _addNewDayTrip() {
    setState(() {
      _multiDayTrips.add({
        'multiTitleController': TextEditingController(),
        'multiContentController': TextEditingController(),
        'multiLocationController': TextEditingController(),
        'multiSelectedLocation': LatLng(0.0, 0.0),
        'latitude': 0.0,
        'longitude': 0.0,
        'images': <File>[],
      });
    });
  }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        onImagePicked(File(pickedFile.path));
      });
    }
  }

  Future<void> _getCurrentLocation(
      TextEditingController controller, int? index) async {
    try {
      // Log initial state
      print('Checking location permissions...');

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      setState(() {
        _isLoading = true;
      });

      // Log before fetching position
      print('Fetching current position...');
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Location request timed out. Please try again.');
      });

      // Log fetched position
      print('Position fetched: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates using geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      print('Location name set to: $_locationName');

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          if (index == null) {
            _selectedLocation = LatLng(position.latitude, position.longitude);
          } else if (index < _multiDayTrips.length) {
            _multiDayTrips[index]['multiSelectedLocation'] =
                LatLng(position.latitude, position.longitude);
            _multiDayTrips[index]['latitude'] = position.latitude;
            _multiDayTrips[index]['longitude'] = position.longitude;
          }
        });
        _locationName = '${place.locality}, ${place.administrativeArea}';
        controller.text = _locationName!;
      }
    } catch (e) {
      print('Error in fetching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationSearchDialog(TextEditingController controller,
      int? index, LatLng? selectedLocation) async {
    TextEditingController searchController = TextEditingController();
    List<Prediction> predictions = [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Search Location'),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Current Location Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _getCurrentLocation(controller, index);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Location Search Field
                  GooglePlaceAutoCompleteTextField(
                    textEditingController: searchController,
                    googleAPIKey: "AIzaSyBSvnqQqYvnRNvYPAYdx55IBKMIGTEJW7U",
                    inputDecoration: InputDecoration(
                      hintText: "Search location",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: Icon(Icons.search),
                    ),
                    debounceTime: 800,
                    countries: ["us", "uk"],
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (Prediction prediction) {
                      controller.text = prediction.description ?? '';

                      double latitude =
                          double.tryParse(prediction.lat ?? "0") ?? 0.0;
                      double longitude =
                          double.tryParse(prediction.lng ?? "0") ?? 0.0;
                      LatLng newLocation = LatLng(latitude, longitude);

                      if (index == null) {
                        _selectedLocation = newLocation;
                      } else if (index < _multiDayTrips.length) {
                        setState(() {
                          _multiDayTrips[index]['multiSelectedLocation'] =
                              newLocation;
                          _multiDayTrips[index]['latitude'] = latitude;
                          _multiDayTrips[index]['longitude'] = longitude;
                        });
                      }
                      _locationName = prediction.description;
                      Navigator.pop(context);
                    },
                    itemClick: (Prediction prediction) {
                      searchController.text = prediction.description ?? '';
                      setState(() {
                        predictions.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: predictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(predictions[index].description ?? ''),
                          onTap: () {
                            _locationController.text =
                                predictions[index].description ?? '';
                            _locationName = predictions[index].description;
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _submitPost() async {
    //Check required fields
    if (_tabController.index == 0) {
      if (_titleController.text.isEmpty ||
          _contentController.text.isEmpty ||
          _locationController.text.isEmpty ||
          _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
        return;
      }
    } else {
      // Multi-Day Post Validation
      bool isValidationFailed = false;

      for (int i = 0; i < _multiDayTrips.length; i++) {
        final day = _multiDayTrips[i];
        final multiTitleController =
            day['multiTitleController'] as TextEditingController?;
        final multiContentController =
            day['multiContentController'] as TextEditingController?;
        final multiLocationController =
            day['multiLocationController'] as TextEditingController?;
        final multiSelectedLocation = day['multiSelectedLocation'] as LatLng?;

        // Log all field values for debugging
        print('Day ${i + 1}');
        print('  Title: ${multiTitleController?.text}');
        print('  Content: ${multiContentController?.text}');
        print('  Location: ${multiLocationController?.text}');
        print('  Selected Location: ${multiSelectedLocation}');

        if (multiTitleController == null ||
            multiTitleController.text.isEmpty ||
            multiContentController == null ||
            multiContentController.text.isEmpty ||
            multiLocationController == null ||
            multiLocationController.text.isEmpty ||
            multiSelectedLocation == null) {
          isValidationFailed = true;
        }
      }

      if (_titleController.text.isEmpty ||
          _locationController.text.isEmpty ||
          _selectedCategory == null ||
          _multiDayTrips.isEmpty ||
          isValidationFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please fill in all required fields for multi-day post')),
        );
        return;
      }
    }

    //Submit all data fields
    setState(() {
      _isLoading = true;
    });
    try {
      final category = _customCategoryController.text.isNotEmpty
          ? _customCategoryController.text
          : _selectedCategory;

      if (_tabController.index == 0) {
        // Single Day Post Submission

        await apiService.createPost(
          title: _titleController.text,
          locationName: _locationController.text,
          latitude: _selectedLocation?.latitude ?? 0.0,
          longitude: _selectedLocation?.longitude ?? 0.0,
          category: category!,
          content: _contentController.text,
          imagePaths: _images.map((file) => file.path).toList(),
          period: 'oneday',
        );
      } else {
        // Multi-Day Post Submission
        final List<Map<String, dynamic>> multiDayTrips =
            _multiDayTrips.map((day) {
          final LatLng selectedLocation =
              day['multiSelectedLocation'] ?? LatLng(0.0, 0.0);

          final childLocationData = {
            'place_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
            'name':
                (day['multiLocationController'] as TextEditingController).text,
            'address':
                (day['multiLocationController'] as TextEditingController).text,
            'latitude': selectedLocation.latitude ?? 0.0,
            'longitude': selectedLocation.longitude ?? 0.0,
          };

          return {
            'title':
                (day['multiTitleController'] as TextEditingController).text,
            'content':
                (day['multiContentController'] as TextEditingController).text,
            'location': childLocationData,
            'category': category!,
            'period': 'oneday',
            'imagePaths':
                (day['images'] as List<File>).map((file) => file.path).toList(),
          };
        }).toList();

        // ✅ Debugging: Print Multi-Day Trips
        print("📤 Multi-Day Post Submission Data:");
        for (int i = 0; i < _multiDayTrips.length; i++) {
          print(
              "📸 Day ${i + 1} has ${_multiDayTrips[i]['images'].length} images.");
        }

        await apiService.createPost(
          title: _titleController.text,
          content: "",
          locationName: _locationController.text,
          latitude: _selectedLocation?.latitude ?? 0.0,
          longitude: _selectedLocation?.longitude ?? 0.0,
          category: category!,
          multiDayTrips: multiDayTrips,
          period: 'multipleday',
        );
      }

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    for (var day in _multiDayTrips) {
      (day['multiTitleController'] as TextEditingController).dispose();
      (day['multiContentController'] as TextEditingController).dispose();
      (day['multiLocationController'] as TextEditingController).dispose();
    }
    super.dispose();
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
            const SizedBox(height: 16),
            _buildTextField('Description', _contentController, maxLines: 5),
            const SizedBox(height: 16),
            _buildLocationField('Location', _locationController, null,
                _selectedLocation ?? LatLng(0.0, 0.0)),
            const SizedBox(height: 16),
            _buildCategorySelector(),
          ],
        ),
      ),
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
          labelStyle: TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildLocationField(String label, TextEditingController controller,
      int? index, LatLng? selectedLocation) {
    return GestureDetector(
      onTap: () {
        _showLocationSearchDialog(
            controller, index, selectedLocation ?? LatLng(0, 0));
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    _getCurrentLocation(controller, index);
                  },
                  tooltip: 'Use current location',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _showLocationSearchDialog(
                        controller, index, selectedLocation ?? LatLng(0, 0));
                  },
                  tooltip: 'Search location',
                ),
              ],
            ),
            // border: UnderlineInputBorder(
            //   borderSide: BorderSide(color: Color.fromARGB(76, 118, 118, 118)),
            // ),
            border: const OutlineInputBorder(),
          ),
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
            _buildTextField('Post Title', _titleController),
            _buildLocationField("General Location", _locationController, null,
                _selectedLocation ?? LatLng(0.0, 0.0)),
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
                      _buildTextField('Day Title', day['multiTitleController']),
                      _buildTextField(
                          'Description', day['multiContentController'],
                          maxLines: 5),
                      _buildLocationField(
                          'Day Location',
                          day['multiLocationController'],
                          index,
                          day['multiSelectedLocation'] ?? LatLng(0.0, 0.0)),
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text('Category', style: TextStyle(fontSize: 16)),
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
            hintStyle: TextStyle(color: Colors.grey),
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
}
