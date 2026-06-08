import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const Color accent = Color(0xFF1FAE6C);

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/201004832172');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp.')),
        );
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Error opening WhatsApp.')),
      );
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+201004832172');
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unable to place a call.')),
        );
      }
    } catch (e) {
      debugPrint('Error placing call: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Error placing call.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز مساعدة'),
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
                    children: const [
                      SizedBox(height: 8),
                      _FaqTile(
                        question: 'How do I unlock a scooter?',
                        answer:
                            'Open the app, tap a scooter, then scan the QR code or enter the scooter code to unlock.',
                      ),
                      _FaqTile(
                        question: 'What if the battery is low?',
                        answer:
                            'Scooters show battery percentage in the details. Only select scooters with sufficient charge for your trip.',
                      ),
                      _FaqTile(
                        question: 'Can I ride on sidewalks?',
                        answer:
                            'Please follow local regulations. Generally, use bike lanes and roads where allowed.',
                      ),
                      _FaqTile(
                        question: 'How are fees calculated?',
                        answer:
                            'Fees are charged per-minute. Unlock fees may apply depending on the scooter model.',
                      ),
                      _FaqTile(
                        question: 'How to report a damaged scooter?',
                        answer:
                            'Use the "Report" option in the scooter details or contact support via chat or call below.',
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
                              'Contact Support',
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
                                label: const Text('Chat on WhatsApp'),
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
                                label: const Text('Call Support'),
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
