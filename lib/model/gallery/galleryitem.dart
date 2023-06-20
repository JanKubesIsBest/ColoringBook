import 'dart:io';

import 'package:coloring_book_for_kids/model/pageViewBuilder.dart';
import 'package:flutter/material.dart';

class GalleryItem extends StatelessWidget {
  final String path;

  const GalleryItem({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {
        // Better to pushReplace so we close our selfs
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => PageViewBuilderForColoringBook(
                prioritizeSome: true, pathOfPrioritized: path),
          ),
        )
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
        ),
      ),
    );
  }
}
