import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:glider/l10n/app_localizations.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const Color accent = Color(0xFF1FAE6C);

  Future<void> _launchWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('https://wa.me/201004832172');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.helpUnableOpenWhatsApp)),
        );
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.helpErrorOpeningWhatsApp)),
      );
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(scheme: 'tel', path: '+201004832172');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.helpUnablePlaceCall)),
        );
      }
    } catch (e) {
      debugPrint('Error placing call: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.helpErrorPlacingCall)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenter),
        backgroundColor: Colors.black,
        foregroundColor: accent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF071018)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      _FaqTile(
                        question: l10n.helpFaqUnlockQuestion,
                        answer: l10n.helpFaqUnlockAnswer,
                      ),
                      _FaqTile(
                        question: l10n.helpFaqBatteryQuestion,
                        answer: l10n.helpFaqBatteryAnswer,
                      ),
                      _FaqTile(
                        question: l10n.helpFaqSidewalkQuestion,
                        answer: l10n.helpFaqSidewalkAnswer,
                      ),
                      _FaqTile(
                        question: l10n.helpFaqFeesQuestion,
                        answer: l10n.helpFaqFeesAnswer,
                      ),
                      _FaqTile(
                        question: l10n.helpFaqReportQuestion,
                        answer: l10n.helpFaqReportAnswer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent, color: accent),
                            const SizedBox(width: 12),
                            Text(
                              l10n.helpContactSupport,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _launchWhatsApp(context),
                                icon: const Icon(Icons.chat),
                                label: Text(l10n.helpChatWhatsApp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _callSupport(context),
                                icon: const Icon(Icons.call),
                                label: Text(l10n.helpCallSupport),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedIconColor: HelpCenterScreen.accent,
      collapsedTextColor: Colors.white70,
      iconColor: HelpCenterScreen.accent,
      textColor: Colors.white,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(answer, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
