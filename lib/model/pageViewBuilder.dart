import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor/editor.dart';

class PageViewBuilderForColoringBook extends StatelessWidget {
  final bool prioritizeSome;
  final String pathOfPrioritized;
  final PageController _pageController = PageController();

  PageViewBuilderForColoringBook(
      {super.key,
      required this.prioritizeSome,
      required this.pathOfPrioritized});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 1,
      ),
      body: FutureBuilder<List<String>>(
        future: getFuturesGoing(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            final List<String> allImages = snapshot.data as List<String>;
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: prioritizeSome ? allImages.length + 1 : allImages.length,
              itemBuilder: (BuildContext context, int index) {
                // If there is prioritized, show it as first thing
                if (prioritizeSome && index == 0) {
                  return Editor(
                    isPrioritized: true,
                    path: pathOfPrioritized,
                    nextPage: () => _pageController.nextPage(
                        duration: const Duration(
                          milliseconds: 500,
                        ),
                        curve: Curves.linear),
                  );
                }else {
                return Editor(
                  isPrioritized: false,
                  // if there is prioritized, be aware that prioritized is in the list
                  path: prioritizeSome ? allImages[index - 1] : allImages[index],
                  nextPage: () => _pageController.nextPage(
                      duration: const Duration(
                        milliseconds: 500,
                      ),
                      curve: Curves.linear),
                );}
              },
            );
          } else {
            return const Align(alignment: Alignment.center, child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<List<String>> getFuturesGoing() async {
    ListResult result = await FirebaseStorage.instance.ref("images").listAll();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var x = prefs.getStringList("viewedImages");
    late List<String> alreadyViewed;
    if (x != null) {
      alreadyViewed = x;
    } else {
      alreadyViewed = [];
    }

    List<String> list = [];
    List<String> addedToTheEnd = [];

    for (var ref in result.items) {
      bool isInViewed = false;
        for (String viewedImage in alreadyViewed) {
          // Here could maybe work fullpath == viewed image, as we are storing paths now, but whatever
          if (ref.fullPath.contains(viewedImage)) {
            isInViewed = true;
          }
        }
        if (isInViewed) {
          print("Added to the end: ${ref.fullPath}");
          addedToTheEnd.add(ref.fullPath);
        } else {
          list.add(ref.fullPath);
        }
    }

    list.addAll(addedToTheEnd);

    return list;
  }
}
