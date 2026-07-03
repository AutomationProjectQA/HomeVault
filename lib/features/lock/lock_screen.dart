import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_lock_service.dart';
import '../../core/theme/tokens.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Prompt immediately on open; the button is the retry path.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    final ok = await ref
        .read(appLockServiceProvider)
        .authenticate('Unlock HomeVault');
    if (!mounted) return;
    if (ok) {
      ref.read(sessionUnlockedProvider.notifier).unlock();
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 64, color: scheme.primary),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'HomeVault is locked',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (_failed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "Couldn't verify. Try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _unlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
