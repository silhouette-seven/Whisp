import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileMessageBubble extends StatefulWidget {
  final String url;
  final String fileName;
  final int size;

  const FileMessageBubble({
    super.key,
    required this.url,
    required this.fileName,
    required this.size,
  });

  @override
  State<FileMessageBubble> createState() => _FileMessageBubbleState();
}

class _FileMessageBubbleState extends State<FileMessageBubble> {
  bool _isDownloading = false;
  bool _fileExists = false;
  bool _isChecking = true;
  double _progress = 0.0;
  CancelToken? _cancelToken;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _fileExists = true;
            _localPath = file.path;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking file existence: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _downloadFile() async {
    if (widget.url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid file URL')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _cancelToken = CancelToken();
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${widget.fileName}';

      await Dio().download(
        widget.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
        cancelToken: _cancelToken,
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _fileExists = true;
          _localPath = savePath;
        });
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('Download canceled');
      } else {
        debugPrint('Download error: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
        }
      }
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = 0.0;
        });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<void> _onTap() async {
    if (_isDownloading) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Cancel Download?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Do you want to cancel the file download?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('No', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    _cancelDownload();
                    Navigator.pop(context);
                  },
                  child: const Text('Yes', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
      );
    } else if (_fileExists && _localPath != null) {
      final result = await OpenFilex.open(_localPath!);
      if (mounted) {
        if (result.type == ResultType.noAppToOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No app found to open this file type.'),
            ),
          );
        } else if (result.type == ResultType.permissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied to open file.')),
          );
        } else if (result.type == ResultType.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${result.message}')),
          );
        }
      }
    } else {
      _downloadFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_fileExists || _isDownloading) ...[
            _buildStatusIcon(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description,
                    color: Colors.black54,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(widget.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isChecking) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _progress,
              color:
                  Colors.white, // Assuming dark background for the chat screen
              strokeWidth: 3,
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Download icon
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color.fromARGB(113, 0, 0, 0), // Black background as per image
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Icon(Icons.arrow_downward, color: Colors.white, size: 24),
    );
  }
}
