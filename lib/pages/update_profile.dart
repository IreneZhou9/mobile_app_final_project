import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components/my_textfield.dart';
import 'display_profile.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  // controllers for bio and description
  TextEditingController bioController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // image storage variables
  File? _image; // for mobile platform
  Uint8List? _webImage; // for web platform
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Select Image Source",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // pick image from selected source
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _image = null; // clear mobile image
          });
        } else {
          setState(() {
            _image = File(pickedFile.path);
            _webImage = null; // clear web image
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image selected successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error selecting image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // submit profile data to firebase
  Future<void> _submitData() async {
    // validate inputs
    if ((_image == null && _webImage == null) || 
        bioController.text.trim().isEmpty || 
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields and select an image"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // upload image and get url
      String? imageUrl = await _uploadImage(_image, _webImage);

      if (imageUrl == null) {
        throw Exception("Failed to upload image");
      }

      // save data to firestore
      await FirebaseFirestore.instance.collection('Image').add({
        'bio': bioController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // navigate to display profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DisplayProfile()),
      );

    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // upload image to firebase storage
  Future<String?> _uploadImage(File? imageFile, Uint8List? webImage) async {
    try {
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child("profile_images/$fileName");

      UploadTask uploadTask;
      
      if (kIsWeb && webImage != null) {
        // upload for web platform
        uploadTask = ref.putData(
          webImage,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && imageFile != null) {
        // upload for mobile platform
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw Exception("No image file available");
      }

      // monitor upload progress
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
      
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception("Image upload failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // image picker section
            GestureDetector(
              onTap: _isUploading ? null : _showImageSourceDialog,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: kIsWeb && _webImage != null
                        ? MemoryImage(_webImage!)
                        : !kIsWeb && _image != null
                            ? FileImage(_image!)
                            : null,
                    child: (_image == null && _webImage == null)
                        ? Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          )
                        : null,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Text(
              "Tap to select image",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),

            // bio input field
            MyTextfield(
              hintText: "Enter your bio",
              obscureText: false,
              controller: bioController,
            ),
            const SizedBox(height: 15),

            // description input field
            MyTextfield(
              hintText: "Enter a description",
              obscureText: false,
              controller: descriptionController,
            ),
            const SizedBox(height: 30),

            // submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Uploading...",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.inversePrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Update Profile",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}