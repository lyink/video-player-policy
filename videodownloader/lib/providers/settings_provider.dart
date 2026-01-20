import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _autoRepeatKey = 'auto_repeat';
  static const String _autoPlayNextKey = 'auto_play_next';
  static const String _volumeBoostKey = 'volume_boost';
  static const String _hardwareAccelerationKey = 'hardware_acceleration';
  static const String _aspectRatioKey = 'aspect_ratio';
  static const String _audioOutputKey = 'audio_output';
  static const String _subtitleFontSizeKey = 'subtitle_font_size';
  static const String _subtitleFontColorKey = 'subtitle_font_color';
  static const String _subtitleBackgroundKey = 'subtitle_background';

  // Playback settings
  bool _autoRepeat = false;
  bool _autoPlayNext = true;
  bool _volumeBoost = false;

  // Video settings
  bool _hardwareAcceleration = true;
  String _aspectRatio = 'Auto-fit';

  // Audio settings
  String _audioOutput = 'Default';

  // Subtitle settings
  String _subtitleFontSize = 'Medium';
  String _subtitleFontColor = 'White';
  String _subtitleBackground = 'Semi-transparent';

  // Premium features (temporary unlocks via ads)
  bool _isAdFreeActive = false;
  bool _isPremiumSpeedUnlocked = false;
  bool _isHDQualityUnlocked = false;
  DateTime? _adFreeExpiryTime;

  // Getters
  bool get autoRepeat => _autoRepeat;
  bool get autoPlayNext => _autoPlayNext;
  bool get volumeBoost => _volumeBoost;
  bool get hardwareAcceleration => _hardwareAcceleration;
  String get aspectRatio => _aspectRatio;
  String get audioOutput => _audioOutput;
  String get subtitleFontSize => _subtitleFontSize;
  String get subtitleFontColor => _subtitleFontColor;
  String get subtitleBackground => _subtitleBackground;
  bool get isAdFreeActive => _isAdFreeActive && (_adFreeExpiryTime?.isAfter(DateTime.now()) ?? false);
  bool get isPremiumSpeedUnlocked => _isPremiumSpeedUnlocked;
  bool get isHDQualityUnlocked => _isHDQualityUnlocked;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _autoRepeat = prefs.getBool(_autoRepeatKey) ?? false;
    _autoPlayNext = prefs.getBool(_autoPlayNextKey) ?? true;
    _volumeBoost = prefs.getBool(_volumeBoostKey) ?? false;
    _hardwareAcceleration = prefs.getBool(_hardwareAccelerationKey) ?? true;
    _aspectRatio = prefs.getString(_aspectRatioKey) ?? 'Auto-fit';
    _audioOutput = prefs.getString(_audioOutputKey) ?? 'Default';
    _subtitleFontSize = prefs.getString(_subtitleFontSizeKey) ?? 'Medium';
    _subtitleFontColor = prefs.getString(_subtitleFontColorKey) ?? 'White';
    _subtitleBackground = prefs.getString(_subtitleBackgroundKey) ?? 'Semi-transparent';

    // Load premium features expiry
    final adFreeExpiryString = prefs.getString('ad_free_expiry');
    if (adFreeExpiryString != null) {
      _adFreeExpiryTime = DateTime.parse(adFreeExpiryString);
      _isAdFreeActive = _adFreeExpiryTime!.isAfter(DateTime.now());
    }

    _isPremiumSpeedUnlocked = prefs.getBool('premium_speed_unlocked') ?? false;
    _isHDQualityUnlocked = prefs.getBool('hd_quality_unlocked') ?? false;

    notifyListeners();
  }

  // Setters with persistence
  Future<void> setAutoRepeat(bool value) async {
    _autoRepeat = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRepeatKey, value);
    notifyListeners();
  }

  Future<void> setAutoPlayNext(bool value) async {
    _autoPlayNext = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayNextKey, value);
    notifyListeners();
  }

  Future<void> setVolumeBoost(bool value) async {
    _volumeBoost = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_volumeBoostKey, value);
    notifyListeners();
  }

  Future<void> setHardwareAcceleration(bool value) async {
    _hardwareAcceleration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardwareAccelerationKey, value);
    notifyListeners();
  }

  Future<void> setAspectRatio(String value) async {
    _aspectRatio = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aspectRatioKey, value);
    notifyListeners();
  }

  Future<void> setAudioOutput(String value) async {
    _audioOutput = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioOutputKey, value);
    notifyListeners();
  }

  Future<void> setSubtitleFontSize(String value) async {
    _subtitleFontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleFontSizeKey, value);
    notifyListeners();
  }

  Future<void> setSubtitleFontColor(String value) async {
    _subtitleFontColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleFontColorKey, value);
    notifyListeners();
  }

  Future<void> setSubtitleBackground(String value) async {
    _subtitleBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleBackgroundKey, value);
    notifyListeners();
  }

  // Premium features management
  Future<void> activateAdFree() async {
    _isAdFreeActive = true;
    _adFreeExpiryTime = DateTime.now().add(const Duration(hours: 24));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ad_free_expiry', _adFreeExpiryTime!.toIso8601String());
    notifyListeners();
  }

  Future<void> unlockPremiumSpeed() async {
    _isPremiumSpeedUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_speed_unlocked', true);
    notifyListeners();
  }

  Future<void> unlockHDQuality() async {
    _isHDQualityUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hd_quality_unlocked', true);
    notifyListeners();
  }

  // Helper methods
  List<String> get availableAspectRatios => ['Auto-fit', '16:9', '4:3', '1:1', 'Stretch'];
  List<String> get availableAudioOutputs => ['Default', 'Speakers', 'Headphones', 'Bluetooth'];
  List<String> get availableSubtitleFontSizes => ['Small', 'Medium', 'Large', 'Extra Large'];
  List<String> get availableSubtitleFontColors => ['White', 'Black', 'Yellow', 'Red', 'Blue'];
  List<String> get availableSubtitleBackgrounds => ['None', 'Semi-transparent', 'Solid', 'Outline'];
}