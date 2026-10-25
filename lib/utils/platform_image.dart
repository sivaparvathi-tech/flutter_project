import 'package:flutter/material.dart';

import 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart' as impl;

/// Proxy so screens can call [platformImage] through a single import.
/// On native platforms it renders an image from a local file path; on web it
/// is a no-op because web products store images as base64 data URIs.
Widget platformImage({
  required String source,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorBuilder,
}) {
  return impl.platformImage(
    source: source,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}