import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// image picker page for selecting photos
class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({Key? key}) : super(key: key);

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 35,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        title: Text(
          "Image Picker",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: ((builder) => _buildImageSourceSelector()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.image_search),
            ),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: _imageBytes == null
              ? Icon(
                  Icons.image_aspect_ratio,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 100,
                )
              : SizedBox(
                  width: 300,
                  height: 300,
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }

  // build image source selection modal
  Widget _buildImageSourceSelector() {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Wrap(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: Text(
              "Select Image Source",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    getImage(ImageSource.camera);
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera,
                        size: 40,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          "Camera",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    getImage(ImageSource.gallery);
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.image,
                        size: 40,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: Text(
                          "Gallery",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(top: 20),
              color: Theme.of(context).colorScheme.secondary,
              child: Text(
                'CLOSE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // get image from selected source
  Future getImage(ImageSource src) async {
    final XFile? image = await _picker.pickImage(source: src);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }
}
