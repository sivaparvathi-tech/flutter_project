import 'dart:io';

import 'package:flutter/material.dart';

/// Renders an image from a local file path (native platforms).
Widget platformImage({
  required String source,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorBuilder,
}) {
  return Image.file(
    File(source),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) =>
        errorBuilder ?? const SizedBox.shrink(),
  );
}