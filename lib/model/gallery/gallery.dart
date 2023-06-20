import 'package:coloring_book_for_kids/model/gallery/galleryitem.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Gallery extends StatelessWidget {
  const Gallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gallery',
          style: TextStyle(fontFamily: "Futura"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: FutureBuilder<List<String>>(
          future: getListStrings(),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData) {
              if ((snapshot.data as List).length == 1) {
                return GalleryItem(path: (snapshot.data as List<String>).first,);
              }
              return SingleChildScrollView(
                primary: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ColumnsOfSavedImages(
                      paths: (snapshot.data as List<String>).sublist(
                          0, ((snapshot.data as List).length / 2).ceil()),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ColumnsOfSavedImages(
                      paths: (snapshot.data as List<String>).sublist(
                          ((snapshot.data as List).length / 2).ceil(),
                          (snapshot.data as List).length),
                    ),
                  ],
                ),
              );
            } else {
              return const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  Future<List<String>> getListStrings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final list = prefs.getStringList("downloaded");

    // Check if the database already exist
    if (list != null) {
      return prefs.getStringList("downloaded") as List<String>;
    } else {
      return [];
    }
  }
}

class ColumnsOfSavedImages extends StatelessWidget {
  final List<String> paths;

  const ColumnsOfSavedImages(
      {super.key, required this.paths});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: paths.length,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [GalleryItem(
              path: paths[index],
            ),
            const SizedBox(
              height: 5,
            ),]
          );
        },
      ),
    );
  }
}
