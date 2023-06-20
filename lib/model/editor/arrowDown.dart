import 'package:flutter/material.dart';

class ArrowDown extends StatelessWidget {
  final Function nextPage;

  const ArrowDown({super.key, required this.nextPage});

  @override
  Widget build(BuildContext context) {
    return           ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: MaterialButton(
        onPressed: () => {nextPage()},
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Go down"),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 40,
            )
          ],
        ),
      ),
    );
  }

}