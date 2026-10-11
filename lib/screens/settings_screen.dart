import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../services/google_auth_service.dart';
import '../services/hangout_repository.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/panel.dart';
import 'storage_dashboard_modal.dart';

/// Settings, laid out like the back panel of a piece of hardware: labelled
/// sections, hairline rules, toggle switches, and a live theme picker.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final repo = HangoutRepository.instance;
    final auth = GoogleAuthService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([theme, repo, auth]),
      builder: (context, _) {
        final user = auth.currentUser;
        final share = repo.selectedHangoutOrNull;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
              padding: EdgeInsets.fromLTRB(
                  0, MediaQuery.paddingOf(context).top + 8, 0, 48),
              children: [
                AppScreenHeader(
                  title: 'settings',
                  subtitle: 'theme · account · privacy',
                  onBack: () => Navigator.maybePop(context),
                ),

                const SectionLabel('APPEARANCE'),
                Panel(
                  child: Column(
                    children: [
                      for (var i = 0; i < AppThemeId.values.length; i++) ...[
                        _ThemeOption(
                          id: AppThemeId.values[i],
                          selected: theme.themeId == AppThemeId.values[i],
                          onTap: () => theme.select(AppThemeId.values[i]),
                          showDivider: i < AppThemeId.values.length - 1,
                        ),
                      ],
                    ],
                  ),
                ),

                // ---- Account ----------------------------------------------
                const SectionLabel('ACCOUNT'),
                Panel(
                  child: Column(
                    children: [
                      if (user != null)
                        _Row(
                          label: 'SIGNED IN',
                          value: user.name,
                          trailing: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(user.avatarUrl),
                          ),
                        ),
                      _Row(
                        label: 'EMAIL',
                        value: user?.subtitle ?? '—',
                      ),
                      _Row(
                        label: 'FACE PROFILE',
                        value: user?.faceVector == null
                            ? 'Not enrolled'
                            : '128-D vector active',
                        valueColor: user?.faceVector == null
                            ? AppColors.textMuted
                            : AppColors.activeGreen,
                      ),
                      _ActionRow(
                        label: 'SIGN OUT',
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) Navigator.maybePop(context);
                        },
                      ),
                    ],
                  ),
                ),

                // ---- Privacy ----------------------------------------------
                if (share != null) ...[
                  const SectionLabel('PRIVACY'),
                  Panel(
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'GHOST MODE BY DEFAULT',
                          help:
                              'New photos of you wait in your Consent Vault before joining the public album.',
                          value: share.ghostModeDefault,
                          onChanged: (v) => repo.updateHostControls(
                            share.id,
                            ghostModeDefault: v,
                          ),
                        ),
                        _ToggleRow(
                          label: 'REQUIRE APPROVAL TO PUBLISH',
                          help: 'Keep unapproved photos out of the group album.',
                          value: share.requireApprovalToPublish,
                          onChanged: (v) => repo.updateHostControls(
                            share.id,
                            requireApprovalToPublish: v,
                          ),
                        ),
                        _ToggleRow(
                          label: 'GUESTS CAN POST',
                          help: 'Turn off to make this a host-only album.',
                          value: share.guestsCanPost,
                          onChanged: (v) => repo.updateHostControls(
                            share.id,
                            guestsCanPost: v,
                          ),
                        ),
                        _ToggleRow(
                          label: 'GUESTS CAN INVITE',
                          help: 'Let anyone share the QR / NFC pass.',
                          value: share.guestsCanInvite,
                          onChanged: (v) => repo.updateHostControls(
                            share.id,
                            guestsCanInvite: v,
                          ),
                          last: true,
                        ),
                      ],
                    ),
                  ),

                  // ---- Storage ----------------------------------------------
                  const SectionLabel('STORAGE'),
                  Panel(
                    child: Column(
                      children: [
                        _Row(
                          label: 'CLOUD TIER',
                          value: share.isDriveLinked
                              ? 'R2 + Google Drive'
                              : 'Cloudflare R2',
                        ),
                        _Row(
                          label: 'EPHEMERAL WINDOW',
                          value: share.ttlLabel,
                          valueColor: share.isExpiringSoon
                              ? AppColors.alertOrange
                              : null,
                        ),
                        _ActionRow(
                          label: 'VIEW STORAGE BREAKDOWN',
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const StorageDashboardModal(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Center(
                  child:                Text(
                  'paper · v1.0.0',
                  style: AppTheme.mono(
                      size: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeId id;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.id,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.6),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Signature dark',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.mono(
                size: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.6),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTheme.mono(
                  size: 11,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  const _ToggleRow({
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.6),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.mono(
                    size: 11,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  help,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
