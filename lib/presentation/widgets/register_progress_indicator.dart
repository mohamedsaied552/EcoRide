import 'package:flutter/material.dart';

class RegisterProgressIndicator extends StatelessWidget {
  const RegisterProgressIndicator({
    required this.currentStep,
    super.key,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StepNode(
                index: 1,
                title: 'Account Details',
                isActive: currentStep >= 1,
                isComplete: currentStep > 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StepNode(
                index: 2,
                title: 'ID Verification',
                isActive: currentStep >= 2,
                isComplete: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: currentStep / 2,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1FAE6C)),
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.title,
    required this.isActive,
    required this.isComplete,
  });

  final int index;
  final String title;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF1FAE6C) : const Color(0xFF98A2B3);
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  fontSize: 15,
                ),
          ),
        ),
      ],
    );
  }
}
