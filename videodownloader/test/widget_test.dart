// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_pro_all_format/models/media_file.dart';

void main() {
  testWidgets('MediaFile model test', (WidgetTester tester) async {
    // Test MediaFile creation
    final mediaFile = MediaFile(
      path: '/test/path/audio.mp3',
      name: 'audio.mp3',
      extension: 'mp3',
      type: MediaType.audio,
    );

    // Verify properties
    expect(mediaFile.path, '/test/path/audio.mp3');
    expect(mediaFile.name, 'audio.mp3');
    expect(mediaFile.extension, 'mp3');
    expect(mediaFile.type, MediaType.audio);
  });

  test('MediaFile JSON serialization', () {
    final mediaFile = MediaFile(
      path: '/test/path/video.mp4',
      name: 'video.mp4',
      extension: 'mp4',
      type: MediaType.video,
    );

    // Test toJson
    final json = mediaFile.toJson();
    expect(json['path'], '/test/path/video.mp4');
    expect(json['name'], 'video.mp4');
    expect(json['type'], 'video');

    // Test fromJson
    final restored = MediaFile.fromJson(json);
    expect(restored.path, mediaFile.path);
    expect(restored.name, mediaFile.name);
    expect(restored.type, mediaFile.type);
  });
}
