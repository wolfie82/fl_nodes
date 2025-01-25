import 'package:flutter/widgets.dart';

extension JSONOffset on Offset {
  static Offset fromJson(List<double> json) => Offset(json[0], json[1]);

  List<double> toJson() => [dx, dy];
}

extension JSONRect on Rect {
  static Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      json['left'] as double,
      json['top'] as double,
      json['width'] as double,
      json['height'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }
}
