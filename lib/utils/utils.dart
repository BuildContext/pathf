import 'package:flutter/material.dart';

import 'path_finder_bfs.dart';

class Utils {
  static void pushSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String pathToString(ShortestPathModel<String> value) {
    var first = '(${value.start.x},${value.start.y})->';
    var middle = value.path.map((e) => '(${e.x},${e.y})->').join();
    var last = '(${value.goal.x},${value.goal.y})';
    return '$first$middle$last';
  }
}
