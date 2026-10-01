import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisionAiPlaceholderCard extends StatelessWidget {
  final String message;
  const VisionAiPlaceholderCard({super.key, this.message = 'INITIALIZING AI VISION STREAM...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.oswald(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
