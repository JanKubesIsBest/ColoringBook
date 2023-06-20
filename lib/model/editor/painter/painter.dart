import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MyPainter extends StatefulWidget {
  final ui.Image image;
  final Function saveThisImageAsViewed;
  final bool isPainting;
  final Color currentColor;
  final bool saveImage;
  final Function saveImageFunction;
  final bool isPrioritized;

  const MyPainter({super.key, required this.image, required this.saveThisImageAsViewed, required this.isPainting, required this.currentColor, required this.saveImage, required this.saveImageFunction, required this.isPrioritized});

  @override
  State<MyPainter> createState() => _MyPainterState();
}

class OffsetAndColor {
  final Offset offset;
  final Color color;

  OffsetAndColor({required this.offset, required this.color});
}

class _MyPainterState extends State<MyPainter> {
  late final ui.Image image = widget.image;

  List<Offset> whereFingerLandedForBlack = [];
  List<OffsetAndColor> whereFingerLandedForDrawing = [];
  final int fingerWidthForBlack = 30;
  final int fingerWidthForPainting = 5;
  int fingerLandedCounter = 0;

  bool thisVersionWasSaved = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: image.width / image.height,
      child: GestureDetector(
        onVerticalDragUpdate: (DragUpdateDetails event) =>
            changeCoordinates(event.localPosition.dx, event.localPosition.dy),
        onHorizontalDragUpdate: (DragUpdateDetails event) =>
            changeCoordinates(event.localPosition.dx, event.localPosition.dy),
        onTapDown: (TapDownDetails event) =>
            changeCoordinates(event.localPosition.dx, event.localPosition.dy),
        child: CustomPaint(
          painter: Black(image: image, whereFingerLandedForBlack: whereFingerLandedForBlack, whereFingerLandedForDrawing: whereFingerLandedForDrawing, fingerWidthForBlack: fingerWidthForBlack, fingerWidthForPainting: fingerWidthForPainting, saveImage: widget.saveImage, saveImageFunction: widget.saveImageFunction, isPrioritized: widget.isPrioritized),
        ),
      ),
    );
  }


  void changeCoordinates(double x, double y) {
    setState(() {
      if (!widget.isPainting) {
        whereFingerLandedForBlack.add(Offset(x, y));
        fingerLandedCounter++;
        // Lets say two thousands is okay for user to see what is behind
        if (fingerLandedCounter >= 1800) {
          widget.saveThisImageAsViewed();
        }
      } else {
        whereFingerLandedForDrawing.add(OffsetAndColor(offset: Offset(x, y), color: widget.currentColor));
      }
    });
  }
}

class Black extends CustomPainter {
  final ui.Image image;

  final List<Offset> whereFingerLandedForBlack;
  final List<OffsetAndColor> whereFingerLandedForDrawing;

  final int fingerWidthForBlack;
  final int fingerWidthForPainting;
  final bool saveImage;

  final Function saveImageFunction;

  final bool isPrioritized;

  Black({required this.saveImageFunction, required this.saveImage, required this.fingerWidthForBlack, required this.fingerWidthForPainting, required this.whereFingerLandedForBlack, required this.whereFingerLandedForDrawing, required this.image, required this.isPrioritized});

  var alreadySaved = false;

  @override
  void paint(Canvas canvas, Size size) {
    if (saveImage && !alreadySaved) {
      final recorder = ui.PictureRecorder();
      final Canvas myCanvas = Canvas(recorder);
      canvasPaint(
          myCanvas,
          size,
          image,
          whereFingerLandedForBlack,
          fingerWidthForBlack,
          whereFingerLandedForDrawing,
          fingerWidthForPainting,
          isPrioritized,);
      saveMyImage(recorder, size);
      alreadySaved = true;
    }
      canvasPaint(canvas, size, image, whereFingerLandedForBlack, fingerWidthForBlack, whereFingerLandedForDrawing, fingerWidthForPainting, isPrioritized);
  }

  @override
  bool shouldRepaint(Black oldDelegate) => true;

  void saveMyImage(ui.PictureRecorder recorder, Size size, ) async {
    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(size.width.floor(), size.height.floor());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data != null) {
      final Uint8List imgBytes = data.buffer.asUint8List();
      print("save image");
      saveImageFunction(imgBytes);
    }
    else {
      print("ERRRRRR");
    }
  }
}

void canvasPaint(Canvas canvas, Size size, ui.Image image, List<Offset> whereFingerLandedForBlack, int fingerWidthForBlack, List<OffsetAndColor> whereFingerLandedForDrawing, int fingerWidthForPainting, bool isPrioritized) {
  canvas.save();
  canvas.scale(
    size.width / image.width,
  );
  canvas.drawImage(image, const ui.Offset(0, 0), Paint());
  canvas.restore();

  // If is prioritized, don't draw image, because user can already know what is underneath
  if (!isPrioritized) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    paintBlack(canvas, size, image, whereFingerLandedForBlack, fingerWidthForBlack);
    canvas.restore();
  }

  canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
  draw(canvas, size, whereFingerLandedForDrawing, fingerWidthForPainting);
  canvas.restore();
}

void draw(Canvas canvas, Size size, List<OffsetAndColor> whereFingerLandedForBlack, int fingerWidth) {
  for (OffsetAndColor x in whereFingerLandedForBlack) {
    final paint2 = Paint()
      ..color = x.color;
    canvas.drawCircle(
        Offset(x.offset.dx, x.offset.dy), fingerWidth.toDouble(), paint2);
  }
}

void paintBlack(Canvas canvas, Size size, ui.Image image, List<Offset> whereFingerLanded, int fingerWidth) {

  final paint1 = Paint()..color = const Color.fromARGB(255, 0, 0, 0);

  canvas.drawRect(const Offset(0, 0) & Size(size.width, size.height), paint1);

  final paint2 = Paint()
    ..color = const Color.fromARGB(0, 0, 0, 0)
    ..blendMode = BlendMode.clear;
  for (Offset finger in whereFingerLanded) {
    canvas.drawCircle(
        Offset(finger.dx, finger.dy), fingerWidth.toDouble(), paint2);
  }
}
