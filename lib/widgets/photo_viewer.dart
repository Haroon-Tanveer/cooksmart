import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Full-screen photo viewer, opened by holding on a recipe's picture.
///
/// Mirrors what a long press does in a photo app: the dish fills the screen on
/// its own, with no card, no text and nothing to tap. Swipe sideways for the
/// other photos of the same recipe, tap anywhere to close.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.sources,
    this.initialIndex = 0,
  });

  /// Image paths or URLs, in gallery order. A local file path is loaded from
  /// disk, anything else is treated as a URL.
  final List<String> sources;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required List<String> sources,
    int initialIndex = 0,
  }) {
    if (sources.isEmpty) return Future<void>.value();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (_, _, _) =>
            PhotoViewer(sources: sources, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ImageProvider _providerFor(String source) {
    // A cached photo lives on disk and must be read from there; a network photo
    // is a URL. Checking the filesystem first avoids treating one as the other.
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    if (File(source).existsSync()) {
      return FileImage(File(source));
    }
    return AssetImage(source);
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final many = widget.sources.length > 1;

    // A full-screen photo is a light-on-dark surface, so the status and
    // navigation bars go light-on-dark for the duration.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                // Tapping the photo itself is the way out, as in a photo app.
                onTap: _close,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.sources.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Image(
                    image: _providerFor(widget.sources[i]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white24,
                        size: 44,
                      ),
                    ),
                    loadingBuilder: (context, child, progress) => progress == null
                        ? child
                        : Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CookColors.orange,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            if (many)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 18,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${_index + 1} of ${widget.sources.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
