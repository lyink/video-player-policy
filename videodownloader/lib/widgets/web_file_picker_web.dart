// Web-specific implementation
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../models/media_file.dart';

class WebFilePicker extends StatelessWidget {
  final Function(MediaFile) onFileSelected;

  const WebFilePicker({super.key, required this.onFileSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Media Files',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose video or audio files from your device to play',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerButton(
                  context,
                  'Video Files',
                  Icons.videocam,
                  Colors.blue,
                  ['mp4', 'avi', 'mkv', 'mov', 'webm'],
                ),
                _buildPickerButton(
                  context,
                  'Audio Files',
                  Icons.music_note,
                  Colors.green,
                  ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Or drag and drop files here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    List<String> extensions,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          onPressed: () => _pickFile(extensions),
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _pickFile(List<String> extensions) {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = extensions.map((ext) => '.$ext').join(',');
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final mediaFile = _createMediaFileFromHtmlFile(file);
        onFileSelected(mediaFile);
      }
    });
  }

  MediaFile _createMediaFileFromHtmlFile(html.File file) {
    final name = file.name;
    final extension = name.split('.').last.toLowerCase();
    final size = file.size;

    MediaType type;
    if (['mp4', 'avi', 'mkv', 'mov', 'webm', 'm4v', '3gp'].contains(extension)) {
      type = MediaType.video;
    } else if (['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'].contains(extension)) {
      type = MediaType.audio;
    } else {
      type = MediaType.unknown;
    }

    // Create a blob URL for the file
    final url = html.Url.createObjectUrlFromBlob(file);

    return MediaFile(
      path: url, // Use blob URL for web
      name: name,
      extension: extension,
      type: type,
      size: size,
      lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified ?? 0),
    );
  }
}