import 'dart:ui';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF69c3cb),
            Color(0xFF5fb7bb),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: avatarUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: size - 4,
                  height: size - 4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                ),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size - 4,
      height: size - 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF69c3cb),
            Color(0xFF5fb7bb),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Blur effects like in React implementation
          Positioned(
            left: 7,
            top: 1,
            child: Container(
              width: size * 0.7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF6dc8cd).withOpacity(0.8),
                borderRadius: BorderRadius.circular(3.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Positioned(
            left: 7,
            bottom: 1,
            child: Container(
              width: size * 0.7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF6dc8cd).withOpacity(0.8),
                borderRadius: BorderRadius.circular(3.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}