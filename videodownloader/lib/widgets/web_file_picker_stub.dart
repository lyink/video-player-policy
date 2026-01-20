// Stub implementation for non-web platforms
import 'package:flutter/material.dart';
import '../models/media_file.dart';

class WebFilePicker extends StatelessWidget {
  final Function(MediaFile) onFileSelected;

  const WebFilePicker({super.key, required this.onFileSelected});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('File picker not available on this platform'),
    );
  }
}