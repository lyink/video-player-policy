import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      20,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (final controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        _controllers.length,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              double height = widget.isPlaying
                  ? 10 + (_animations[index].value * 60)
                  : 15;

              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 2,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}