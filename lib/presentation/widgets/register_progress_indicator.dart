import 'package:flutter/material.dart';

import 'package:glider/l10n/app_localizations.dart';

class RegisterProgressIndicator extends StatelessWidget {
  const RegisterProgressIndicator({
    required this.currentStep,
    super.key,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StepNode(
                index: 1,
                title: l10n.accountDetails,
                isActive: currentStep >= 1,
                isComplete: currentStep > 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StepNode(
                index: 2,
                title: l10n.idVerification,
                isActive: currentStep >= 2,
                isComplete: currentStep > 2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StepNode(
                index: 3,
                title: l10n.selfieVerification,
                isActive: currentStep >= 3,
                isComplete: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: currentStep / 3,
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
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
