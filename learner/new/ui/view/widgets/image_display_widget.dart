import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageDisplayWidget extends StatelessWidget {
  final XFile? imageFile;
  final Uint8List? webImageBytes;
  final bool noEnlargeView;

  const ImageDisplayWidget({
    super.key,
    this.imageFile,
    this.webImageBytes,
    this.noEnlargeView = false,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = MediaQuery.of(context).size.shortestSide * 0.7;

    if (imageFile == null && webImageBytes == null) {
      return Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey.shade500),
              const SizedBox(height: 10),
              Text(
                'No image selected',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageWidget = kIsWeb && webImageBytes != null
        ? Image.memory(webImageBytes!, fit: BoxFit.contain)
        : imageFile != null
            ? Image.file(File(imageFile!.path), fit: BoxFit.contain)
            : const CircularProgressIndicator();

    if (noEnlargeView) {
      return Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: imageWidget,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: AspectRatio(
                aspectRatio: 1,
                child: kIsWeb && webImageBytes != null
                    ? Image.memory(webImageBytes!, fit: BoxFit.contain)
                    : imageFile != null
                        ? Image.file(File(imageFile!.path), fit: BoxFit.contain)
                        : const CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: imageWidget,
        ),
      ),
    );
  }
}
