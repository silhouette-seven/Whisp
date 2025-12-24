import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/chat_service.dart';
import '../widgets/cached_image_widget.dart';
import '../widgets/file_message_bubble.dart';
import '../widgets/user_presence_indicator.dart';
import '../widgets/background_container.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String recipientImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);

  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _uploadProgress.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    final messageId = FirebaseFirestore.instance.collection('users').doc().id;
    final currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _pendingMessages.add({
        'id': messageId,
        'content': content,
        'senderId': currentUser?.uid,
        'type': 'text',
        'timestamp': Timestamp.now(),
        'status': 'sending',
      });
    });
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        widget.chatId,
        content,
        messageId: messageId,
      );
      // No need to manually update status to 'sent' here,
      // the stream will update and we filter out pending messages that exist in stream
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
        setState(() {
          _pendingMessages.removeWhere((m) => m['id'] == messageId);
        });
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        if (mounted) {
          _showImagePreviewDialog(File(photo.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImagePreviewDialog(File imageFile) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'Send Image?',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Image.file(imageFile, height: 200, fit: BoxFit.cover)],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendImage(imageFile);
                },
                child: const Text('Send', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  Future<void> _sendImage(File imageFile) async {
    _uploadProgress.value = 0.0;
    setState(() => _isUploading = true);
    try {
      final imageUrl = await _chatService.uploadChatImage(
        widget.chatId,
        imageFile,
        onProgress: (progress) {
          _uploadProgress.value = progress;
        },
      );
      await _chatService.sendMessage(widget.chatId, imageUrl, type: 'image');
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final time = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return time;
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday $time';
    } else {
      return '${date.day}/${date.month}/${date.year} $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true, // Important for content behind AppBar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              widget.recipientImage.isNotEmpty
                  ? CachedImageWidget(
                    imageUrl: widget.recipientImage,
                    width: 36,
                    height: 36,
                    isCircle: true,
                    fit: BoxFit.cover,
                    placeholder: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.pink[200],
                      child: Text(
                        widget.recipientName.isNotEmpty
                            ? widget.recipientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    errorWidget: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.pink[200],
                      child: Text(
                        widget.recipientName.isNotEmpty
                            ? widget.recipientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  : CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.pink[200],
                    child: Text(
                      widget.recipientName.isNotEmpty
                          ? widget.recipientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              const SizedBox(width: 10),
              Text(
                widget.recipientName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Online status indicator
              UserPresenceIndicator(userId: widget.recipientId),
            ],
          ),
        ),
        body: SafeArea(
          // Remove top padding if you want content to start right under/behind app bar
          // But usually for chat list we want it below app bar.
          // Since we use extendBodyBehindAppBar, SafeArea will handle top padding automatically.
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final streamMessages =
                        docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['id'] = doc.id;
                          return data;
                        }).toList();

                    // Filter out pending messages that are already in the stream
                    final pending =
                        _pendingMessages.where((pendingMsg) {
                          return !streamMessages.any(
                            (streamMsg) => streamMsg['id'] == pendingMsg['id'],
                          );
                        }).toList();

                    // Combine and sort
                    final allMessages = [...streamMessages, ...pending];
                    allMessages.sort((a, b) {
                      final t1 = a['timestamp'] as Timestamp?;
                      final t2 = b['timestamp'] as Timestamp?;
                      if (t1 == null || t2 == null) return 0;
                      return t2.compareTo(t1); // Descending
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Show newest at bottom
                      itemCount: allMessages.length,
                      itemBuilder: (context, index) {
                        final data = allMessages[index];
                        final isMe = data['senderId'] == currentUser?.uid;

                        return _buildMessageBubble(data, isMe);
                      },
                    );
                  },
                ),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _uploadProgress,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(value: value);
                    },
                  ),
                ),
              _buildMessageInput(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final content = data['content'] as String? ?? '';
    final type = data['type'] as String? ?? 'text';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeString = _formatTimestamp(timestamp);
    final status =
        data['status'] as String? ?? 'sent'; // Default to sent if from DB

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[300]!.withAlpha(230),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft:
                isMe ? const Radius.circular(24) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedImageWidget(
                  imageUrl: content,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[400],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[400],
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              )
            else if (type == 'file')
              FileMessageBubble(
                url: data['url'] as String? ?? '',
                fileName: data['fileName'] ?? 'Unknown File',
                size: data['size'] ?? 0,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  content,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  timeString,
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          status == 'sending'
                              ? Colors.red
                              : Colors.green, // Red = Sending, Green = Sent
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // We handle the blur ourselves
      builder:
          (context) => Stack(
            children: [
              // Blur effect
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),
              ),
              // Central Content
              Center(
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.camera_alt_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromCamera();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildAttachmentOption(
                        icon: Icons.image_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImageFromGallery();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildAttachmentOption(
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          _pickFile();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (photo != null) {
        if (mounted) {
          _showImagePreviewDialog(File(photo.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        int size = await file.length();

        if (size > 3 * 1024 * 1024) {
          // 3MB limit
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File too large. Max size is 3MB.')),
            );
          }
          return;
        }

        _sendFile(file, result.files.single.name);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _sendFile(File file, String fileName) async {
    _uploadProgress.value = 0.0;
    setState(() {
      _isUploading = true;
    });

    try {
      final fileData = await _chatService.uploadFile(
        file,
        widget.chatId,
        fileName,
        (progress) {
          _uploadProgress.value = progress;
        },
      );

      await _chatService.sendMessage(
        widget.chatId,
        fileData, // Pass metadata map
        type: 'file',
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send file: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          // Dark, semi-transparent background to let texture show through
          color: const Color.fromARGB(255, 241, 237, 237).withOpacity(0.85),
          // Slightly less rounded corners (Squircle) to match message bubbles
          borderRadius: BorderRadius.circular(24),
          // Subtle border to separate input from the dark wallpaper
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.black,
              ),
              onPressed: _showAttachmentOverlay,
              constraints: const BoxConstraints(),
              // visualDensity ensures the button doesn't take up too much whitespace
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Colors.black,
                ), // White text for contrast
                cursorColor: Colors.black,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Colors.black45,
                  ), // Muted hint text
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black),
              onPressed: _sendMessage,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
