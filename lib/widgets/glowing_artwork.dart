import 'package:flutter/material.dart';

class GlowingArtwork extends StatefulWidget {
  final Widget child;
  final bool isPlaying;

  const GlowingArtwork({
    super.key,
    required this.child,
    required this.isPlaying,
  });

  @override
  State<GlowingArtwork> createState() => _GlowingArtworkState();
}

class _GlowingArtworkState extends State<GlowingArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(GlowingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0); // Reset to no glow when paused
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              // Static shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
              // Glowing shadow
              if (widget.isPlaying)
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  blurRadius: 50 + _animation.value,
                  spreadRadius: _animation.value / 2,
                ),
            ],
          ),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
