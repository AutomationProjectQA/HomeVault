import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/tokens.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.shield_outlined, size: 72, color: scheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'HomeVault',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Everything about your home,\nin one place.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _PromiseRow(
                  icon: Icons.receipt_long_outlined,
                  text: 'Never miss a bill, renewal, or service'),
              const _PromiseRow(
                  icon: Icons.description_outlined,
                  text: 'Every invoice and warranty, always findable'),
              const _PromiseRow(
                  icon: Icons.family_restroom_outlined,
                  text: 'Your whole family sees the same home'),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.read(analyticsProvider).logEvent(
                      AnalyticsEvents.onboardingStep, {'step': 'welcome_done'});
                  context.go(Routes.createHome);
                },
                child: const Text('Get started'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Free · Private · Works offline',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => context.push(Routes.privacy),
                child: const Text('How we handle your data',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
