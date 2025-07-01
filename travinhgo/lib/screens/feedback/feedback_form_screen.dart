import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travinhgo/Models/feedback/feedback_request.dart';

import '../../services/feedback_service.dart';
import '../../utils/constants.dart';
import '../../widget/status_dialog.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final TextEditingController _controller = TextEditingController();
  File? _selectedImage;
  bool _isSending = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Check allowed extensions (chỉ jpg, jpeg, png)
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        final List<String> validExtensions = ['jpg', 'jpeg', 'png'];

        if (!validExtensions.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chỉ chọn ảnh JPG hoặc PNG.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra khi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (text.length < 10 || text.length > 1000) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatusDialog(
          isSuccess: false,
          title: 'Invalid Feedback',
          message: 'Feedback must be between 10 and 1000 characters.',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
      return;
    }
    setState(() => _isSending = true);

    // Chuẩn bị danh sách ảnh nếu có
    List<File>? images;
    if (_selectedImage != null) {
      images = [_selectedImage!];
    }

    FeedbackRequest feedbackRequest = FeedbackRequest(
      content: _controller.text.trim(),
      images: images,
    );
    final ok = await FeedbackService().sendFeedback(feedbackRequest);

    setState(() {
      _isSending = false;
    });

    if (ok) {
      setState(() {
        _controller.clear(); // Xoá text feedback
        _selectedImage = null; // Xoá ảnh đã chọn
        // _isSending = false; // Đã set ở trên rồi, không cần nữa
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatusDialog(
          isSuccess: true,
          title: 'Success',
          message: 'Profile updated successfully',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => StatusDialog(
          isSuccess: false,
          title: 'Error',
          message: 'Failed to send your feedback',
          onOkPressed: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }
  
  

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      backgroundColor: kbackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Feedback',
          style: TextStyle(
            color: Color(0xFF18813B), // Green color
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: Colors.black),
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                '"Your feedback helps us improve and deliver a better experience. Thank you for being with TraVinhGo!"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                  color: Color(0xFF292929),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add feedback',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F2B7C),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Got more feedback? Just type it here...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.photo_on_rectangle,
                              color: Color(0xFF18813B),
                              size: 28,
                            ),
                          ),
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(width: 8),
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  _selectedImage!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          color: (_controller.text.trim().isEmpty || _isSending)
                              ? const Color(0xFFB0ABA7)
                              : kprimaryColor, 
                          borderRadius: BorderRadius.circular(8),
                          onPressed: (_controller.text.trim().isEmpty || _isSending)
                              ? null
                              : _sendFeedback,
                          child: _isSending
                              ? const CupertinoActivityIndicator(radius: 10)
                              : const Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}