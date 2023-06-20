import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:coloring_book_for_kids/model/editor/arrowDown.dart';
import 'package:coloring_book_for_kids/model/editor/colorPicker/colorPicker.dart';
import 'package:coloring_book_for_kids/model/editor/painter/painter.dart';
import 'package:coloring_book_for_kids/model/gallery/gallery.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Editor extends StatefulWidget {
  final String path;
  final Function nextPage;
  final bool isPrioritized;

  const Editor({super.key, required this.path, required this.nextPage, required this.isPrioritized});

  @override
  State<Editor> createState() => _Editor();
}

class _Editor extends State<Editor> {
  bool downloaded = false;
  bool saveImageNow = false;

  // This should be first color in color list
  Color currentColor = const Color.fromARGB(255, 255, 0, 0);
  bool isPainting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FutureBuilder<ui.Image>(
              // Flutter is so retarded that it does not allow me to return ui.Image when the future does not work...
              future: _loadImage(),
              builder: (BuildContext context, image) {
                if (image.hasError) {
                  print(image.error);
                }
                if (image.hasData) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MyPainter(
                      isPrioritized: widget.isPrioritized,
                      image: image.data as ui.Image,
                      saveThisImageAsViewed: saveThisImageAsViewed,
                      isPainting: isPainting,
                      currentColor: currentColor,
                      saveImage: saveImageNow,
                      saveImageFunction: download,
                    ),
                  );
                } else {
                  return const SizedBox(
                    height: 400,
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.brush),
                      onPressed: () => changeIsPainting(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isPainting ? currentColor : Colors.grey),
                    ),
                    isPainting
                        ? ColorPicker(
                            140,
                            colorChangeHandler: colorChangeHandler,
                          )
                        : const SizedBox(
                            height: 35,
                            width: 140,
                          ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: !downloaded
                          ? const Icon(Icons.download)
                          : const Icon(Icons.download_done),
                      onPressed: () => {
                        if (!saveImageNow)
                          {
                            saveImageNow = true,
                          downloaded = true,
                            setState(() {})
                          }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              downloaded ? Colors.green : Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_album),
                      onPressed: () => goToGallery(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          ArrowDown(nextPage: widget.nextPage),
          const SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }

  void changeIsPainting() {
    setState(() {
      isPainting = !isPainting;
    });
  }

  void colorChangeHandler(Color c) {
    setState(() {
      currentColor = c;
    });
  }

  void saveThisImageAsViewed() async {
    if (widget.isPrioritized) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> alreadyViewedImages = getStringList(prefs, "viewedImages");

    if (alreadyViewedImages.contains(widget.path)) return;

    prefs.setStringList("viewedImages",
        [...getStringList(prefs, "viewedImages"), widget.path]);
  }

  Future<String> getImageName() async {
    return "output${await getOutputCounter()}.png";
  }

  Future<int> getOutputCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? outputNumber = prefs.getInt("outputCounter");
    if (outputNumber != null) {
      prefs.setInt("outputCounter", outputNumber + 1);
      return outputNumber + 1;
    } else {
      prefs.setInt("outputCounter", 0);
      return 0;
    }
  }

  void download(Uint8List bytes) async {
    setState(() {
      saveImageNow = false;
    });
    print("Save image is: $saveImageNow");
    // Remove images from path so we don't have to create new folder
    final saveDir = await getApplicationDocumentsDirectory();
    // Get image name and replace end with png
    String imageName = await getImageName();
    String path = '${saveDir.path}/$imageName';
    File saveFile = File(path);
    saveFile.writeAsBytes(bytes);

    // Save image path to downloaded
    storeStringList(path);

    print(path);
  }

  void storeStringList(String newItem) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        "downloaded", [...getStringList(prefs, "downloaded"), newItem]);
  }

  List<String> getStringList(SharedPreferences prefs, String name) {
    final list = prefs.getStringList(name);

    // Check if the database already exist
    if (list != null) {
      return list;
    } else {
      return [];
    }
  }

  void goToGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Gallery(),
      ),
    );
  }

  Future<ui.Image> _loadImage() async {
    if (widget.isPrioritized) {
      File file = File(widget.path);
      Uint8List bytes = await file.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(bytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    }
    try {
      // Create a storage reference from our app
      final storageRef = FirebaseStorage.instance.ref();

      // Create a reference with an initial file path and name
      final pathReference = storageRef.child(widget.path);

      final bytes = await pathReference.getData() as Uint8List;

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);

      final ui.Image image = (await codec.getNextFrame()).image;

      return image;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(e);
      }
        Uint8List blankBytes = const Base64Codec().decode("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7");
        final codec = await instantiateImageCodec(blankBytes);
        final frameInfo = await codec.getNextFrame();
        return frameInfo.image;
    }
  }
}
