import 'package:flutter/material.dart';

class SpaceBackground extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;
  final double overlayOpacity;

  const SpaceBackground({
    super.key,
    required this.child,
    this.overlayColor,
    this.overlayOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Rotated and scaled background image - fills entire screen
        Transform.rotate(
          angle: 0, // Slight rotation (~17 degrees)
          child: Transform.scale(
            scale: 1.3, // 120% of original size to fill when rotated
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background3.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        // Optional overlay for better content visibility
        if (overlayOpacity > 0)
          Container(
            decoration: BoxDecoration(
              color: (overlayColor ?? Colors.black).withValues(
                alpha: overlayOpacity,
              ),
            ),
          ),
        // Content
        child,
      ],
    );
  }
}
