import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool isCircle;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.isCircle = false,
  }) : super(key: key);

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  final ImageCacheService _cacheService = ImageCacheService();
  late Future<String> _imagePathFuture;

  @override
  void initState() {
    super.initState();
    _imagePathFuture = _cacheService.getCachedImagePath(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imagePathFuture = _cacheService.getCachedImagePath(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _imagePathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child:
                widget.placeholder ??
                const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child:
                widget.errorWidget ??
                const Icon(Icons.error, color: Colors.red),
          );
        }

        final path = snapshot.data!;
        ImageProvider imageProvider;

        if (path.startsWith('http')) {
          imageProvider = NetworkImage(path);
        } else {
          imageProvider = FileImage(File(path));
        }

        Widget image = Image(
          image: imageProvider,
          width: widget.width,
          height: widget.height,
          fit: widget.fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child:
                  widget.errorWidget ??
                  const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );

        if (widget.isCircle) {
          return ClipOval(child: image);
        }

        return image;
      },
    );
  }
}
