import 'package:flutter/services.dart';
import 'dart:io';

class IntentService {
  static const platform = MethodChannel('com.lyinkjr.videodownloader/intent');
  static Function(String)? onIntentReceived;

  static Future<void> initialize() async {
    // Set up method call handler for new intents
    platform.setMethodCallHandler(_handleMethodCall);

    // Check for initial intent when app starts
    await checkInitialIntent();
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNewIntent':
        await _handleIntent(call.arguments);
        break;
    }
  }

  static Future<void> checkInitialIntent() async {
    try {
      final result = await platform.invokeMethod('getInitialIntent');
      if (result != null) {
        await _handleIntent(result);
      }
    } catch (e) {
      print('Error checking initial intent: $e');
    }
  }

  static Future<void> _handleIntent(dynamic intentData) async {
    if (intentData == null) return;

    final Map<String, dynamic> data = Map<String, dynamic>.from(intentData);
    final String action = data['action'] ?? '';
    final String uri = data['uri'] ?? '';
    final String path = data['path'] ?? '';
    final String type = data['type'] ?? '';

    print('Intent received - Action: $action, URI: $uri, Type: $type');

    if (action == 'android.intent.action.VIEW' && uri.isNotEmpty) {
      String? filePath;

      if (uri.startsWith('file://')) {
        filePath = uri.substring(7); // Remove 'file://' prefix
      } else if (uri.startsWith('content://')) {
        // For content URIs, we'll use the URI as-is
        filePath = uri;
      } else if (path.isNotEmpty) {
        filePath = path;
      }

      if (filePath != null) {
        // Validate that the file exists (for file:// URIs)
        if (filePath.startsWith('/') && !File(filePath).existsSync()) {
          print('File does not exist: $filePath');
          return;
        }

        // Notify listeners about the intent
        if (onIntentReceived != null) {
          onIntentReceived!(filePath);
        }

        print('Opening file: $filePath');
      }
    }
  }

  static void setIntentHandler(Function(String) handler) {
    onIntentReceived = handler;
  }
}