import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travinhgo/Models/feedback/feedback_request.dart';

import '../../services/feedback_service.dart';
import '../../utils/constants.dart';
import '../../widget/status_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Check allowed extensions (chỉ jpg, jpeg, png)
        final String extension = pickedFile.path.split('.').last.toLowerCase();
        final List<String> validExtensions = ['jpg', 'jpeg', 'png'];

        if (!validExtensions.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.selectJpgOrPng),
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .imagePickerError(e.toString()))),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (text.length > 1000) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatusDialog(
          isSuccess: false,
          title: AppLocalizations.of(context)!.invalidFeedback,
          message: AppLocalizations.of(context)!.feedbackLengthError,
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
          title: AppLocalizations.of(context)!.success,
          message: AppLocalizations.of(context)!.feedbackSentSuccess,
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
          title: AppLocalizations.of(context)!.error,
          message: AppLocalizations.of(context)!.feedbackSentError,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.feedbackTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.feedbackQuote,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.addFeedback,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLength: 1000,
                      minLines: 3,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      style:
                          TextStyle(fontSize: 16, color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.typeFeedbackHint,
                        hintStyle:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
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
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: colorScheme.onPrimaryContainer,
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
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_controller.text.trim().isEmpty || _isSending)
                                    ? colorScheme.onSurface.withOpacity(0.5)
                                    : colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                          ),
                          onPressed:
                              (_controller.text.trim().isEmpty || _isSending)
                                  ? null
                                  : _sendFeedback,
                          child: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.send,
                                  style: const TextStyle(
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
