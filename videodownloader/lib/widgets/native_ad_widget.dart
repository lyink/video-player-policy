import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Try to get existing native ad
    _nativeAd = AdMobService.getNativeAd();

    if (_nativeAd == null) {
      // Load a new one if not available
      AdMobService.loadNativeAd();
      // Wait a bit and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _nativeAd = AdMobService.getNativeAd();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Don't dispose the ad here as it's managed by AdMobService
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 300,
          ),
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}
