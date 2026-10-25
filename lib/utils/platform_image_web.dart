import 'package:flutter/material.dart';

/// Stub used on web where dart:io (File) is unavailable.
/// Web products store images as base64 data URIs, so local file paths never
/// reach this widget.
Widget platformImage({
  required String source,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorBuilder,
}) {
  return errorBuilder ?? const SizedBox.shrink();
}