import 'package:flutter/material.dart';
import 'package:writeright/new/data/services/image_cache.dart';

class ExerciseViewModel extends ChangeNotifier {
  CommonImageCache imageCache;
  ExerciseViewModel({
    required this.imageCache,
  });

  Widget get backgroundImage {
    return imageCache.getBackgroundWidget(darkened: true);
  }

}