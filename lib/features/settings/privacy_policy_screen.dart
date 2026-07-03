import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Plain-language privacy policy (DPDP-aligned). Legal review before the
/// Play Store listing — Sprint 6 story 6.5.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _Section(
            title: 'Your data is yours',
            body:
                'Everything you add to HomeVault — appliances, bills, documents, '
                'photos — belongs to you. You can export it or delete it, '
                'completely, at any time from Settings.',
          ),
          _Section(
            title: 'What we store',
            body:
                'Your home records are stored on your device first, and synced '
                'to secure cloud storage so your family can see the same home '
                'and you never lose data with a lost phone. Data is encrypted '
                'in transit and at rest.',
          ),
          _Section(
            title: 'What we never ask for',
            body:
                'HomeVault has no fields for Aadhaar, PAN, or bank credentials, '
                'and we will never ask for them.',
          ),
          _Section(
            title: 'Permissions',
            body:
                'Camera and photos are used only when you scan an invoice or '
                'attach a picture. Notifications are used for the reminders '
                'you create. Every permission is optional and asked for in '
                'context, with a reason.',
          ),
          _Section(
            title: 'Analytics',
            body:
                'We collect anonymous usage events (like "asset added") to '
                'improve the app. No document contents, names, or amounts are '
                'included. You can turn this off in Settings at any time.',
          ),
          _Section(
            title: 'Contact',
            body: 'Questions or data requests: mgondaliya1210@gmail.com',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(body,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
