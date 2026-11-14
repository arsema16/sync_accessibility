import 'package:flutter/material.dart';

/// Large circular microphone button used on voice-input onboarding steps.
class SyncVoiceMicButton extends StatelessWidget {
  const SyncVoiceMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback? onTap;

  static const Color _teal = Color(0xFF1B7A6E);
  static const Color _tealLight = Color(0xFFB2DFDB);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListening ? 'Listening' : 'Tap to record your answer by voice',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: _tealLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
